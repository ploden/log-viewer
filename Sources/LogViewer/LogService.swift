//
//  LogService.swift
//  Remote
//
//  Created by Philip Loden on 5/20/25.
//

import Foundation
import OSLog
import Combine
import SwiftUI
import ServiceProtocol

public struct LogServiceData {
    var logEntries: [LogEntry]
}

public class LogService: ServiceProtocol {
    public func stop() {}
    
    public typealias ServiceModel = LogServiceData
    
    private var logEntries: [LogEntry] = []
    private var isPaused: Bool = false
    private var searchText: String = ""
    private var selectedCategories: Set<String> = []
    private var allAvailableCategories: Set<String> = []
    private var selectedLogLevels: Set<OSLogEntryLog.Level> = [.debug, .info, .notice, .error, .fault]
    private var categoryLogLevels: [String: Set<OSLogEntryLog.Level>] = [:]
    
    private var logStore: OSLogStore?
    private var pollTimer: Timer?
    private var lastPollDate: Date?
    private var pollLogsTask: Task<Void, Never>?
    private let updateInterval: TimeInterval = 1.0
    private let logger = Logger(subsystem: "com.logviewer.service", category: "LogService")
    
    // ServiceProtocol requirements
    public var continuations: [ServiceContinuation.Continuation] = []
    
    public var currentServiceState: ServiceState<LogServiceData> {
        return .loaded(LogServiceData(logEntries: logEntries))
    }
    
    public var mostRecentLoadedServiceState: ServiceState<LogServiceData>? {
        return currentServiceState
    }
    
    public init() {
        logger.info("LogService initializing...")
        setupLogStore()
        loadCategories()
        startObservingLogs()
        logger.info("LogService initialized with \(self.selectedCategories.count) categories")
    }
    
    private func setupLogStore() {
        do {
            // Try currentProcessIdentifier first, which should definitely capture our own logs
            logStore = try OSLogStore(scope: .currentProcessIdentifier)
            logger.info("OSLogStore created successfully with currentProcessIdentifier scope")
        } catch {
            logger.error("Failed to create log store: \(error.localizedDescription)")
        }
    }
    
    private func loadCategories() {
        guard let url = Bundle.main.url(forResource: "LogViewerLoggerSettings", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let categoriesDict = plist["categories"] as? [String: Bool] else {
            logger.warning("Failed to load LogViewerLoggerSettings.plist or parse categories")
            return
        }
        
        allAvailableCategories = Set(categoriesDict.keys)
        selectedCategories = Set(categoriesDict.keys.filter { categoriesDict[$0] == true })
        
        // Initialize category log levels with all levels selected for ALL categories
        for category in allAvailableCategories {
            categoryLogLevels[category] = [.debug, .info, .notice, .error, .fault]
        }
        
        let categoryList = allAvailableCategories.sorted().joined(separator: ", ")
        logger.info("Loaded categories from plist: [\(categoryList)]")
        logger.info("Initially selected categories: [\(self.selectedCategories.sorted().joined(separator: ", "))]")
    }
    
    private func startObservingLogs() {
        // Start from 30 seconds ago to capture any logs from app startup
        lastPollDate = Date().addingTimeInterval(-30.0)
        pollTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.pollLogs()
        }
        logger.info("Started observing logs with \(self.updateInterval)s interval")
    }
    
    private func pollLogs() {
        guard !isPaused,
              let logStore = logStore,
              let lastDate = lastPollDate else {
            return
        }

        guard pollLogsTask == nil else {
            return
        }

        pollLogsTask = Task {
            do {
                let entries = try logStore.getEntries(matching: nil)
                let entriesArray = Array(entries)
                lastPollDate = Date()

                let newEntries = entriesArray.compactMap { entry -> LogEntry? in
                    guard let logEntry = entry as? OSLogEntryLog,
                          logEntry.date >= lastDate else {
                        return nil
                    }

                    return LogEntry(
                        timestamp: logEntry.date,
                        level: logEntry.level,
                        category: logEntry.category,
                        subsystem: logEntry.subsystem,
                        message: logEntry.composedMessage
                    )
                }

                if !newEntries.isEmpty {
                    DispatchQueue.main.async {
                        self.pollLogsTask = nil
                        self.logEntries.append(contentsOf: newEntries)
                        self.logger.debug("Added \(newEntries.count) new log entries (total: \(self.logEntries.count))")
                        self.updateSubscribers()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.pollLogsTask = nil
                    }
                }
            } catch {
                logger.error("Failed to poll logs: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.pollLogsTask = nil
                }
            }
        }
    }
    
    func getCategoryLogLevels(_ category: String) -> Set<OSLogEntryLog.Level> {
        return categoryLogLevels[category] ?? [.debug, .info, .notice, .error, .fault]
    }
    
    func setCategoryLogLevel(_ category: String, level: OSLogEntryLog.Level, isSelected: Bool) {
        var levels = categoryLogLevels[category] ?? [.debug, .info, .notice, .error, .fault]
        if isSelected {
            levels.insert(level)
        } else {
            levels.remove(level)
        }
        categoryLogLevels[category] = levels
        updateSubscribers()
    }
    
    func togglePause() {
        isPaused.toggle()
        logger.notice("Log monitoring \(self.isPaused ? "paused" : "resumed")")
        updateSubscribers()
    }
    
    func clearLogs() {
        let previousCount = logEntries.count
        logEntries.removeAll()
        logger.notice("Cleared \(previousCount) log entries")
        updateSubscribers()
    }
    
    func setSearchText(_ text: String) {
        searchText = text
        updateSubscribers()
    }
    
    func setSelectedCategories(_ categories: Set<String>) {
        selectedCategories = categories
        updateSubscribers()
    }
    
    func setSelectedLogLevels(_ levels: Set<OSLogEntryLog.Level>) {
        selectedLogLevels = levels
        updateSubscribers()
    }
    
    func getLogEntries() -> [LogEntry] {
        return logEntries
    }
    
    func getIsPaused() -> Bool {
        return isPaused
    }
    
    func getSearchText() -> String {
        return searchText
    }
    
    func getSelectedCategories() -> Set<String> {
        return selectedCategories
    }
    
    func getSelectedLogLevels() -> Set<OSLogEntryLog.Level> {
        return selectedLogLevels
    }
    
    func getAllAvailableCategories() -> Set<String> {
        return allAvailableCategories
    }
    
    // ServiceProtocol requirement
    public func load() {
        updateSubscribers()
    }
    
    func testLogStatement() {
        logger.notice("TEST: This is a test log statement from LogService")
        print("TEST: Created test log statement")
    }
    
    deinit {
        pollTimer?.invalidate()
    }
}
