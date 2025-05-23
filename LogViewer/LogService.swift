//
//  LogService.swift
//  Remote
//
//  Created by Philip Loden on 5/20/25.
//

import Foundation
import OSLog
import Combine

struct LogServiceData {
    var logEntries: [LogEntry]
}

public class LogService: ServiceProtocol {
    typealias ServiceModel = LogServiceData
    
    private var logEntries: [LogEntry] = []
    private var isPaused: Bool = false
    private var searchText: String = ""
    private var selectedCategories: Set<String> = []
    private var selectedLogLevels: Set<OSLogEntryLog.Level> = [.debug, .info, .notice, .error, .fault]
    private var categoryLogLevels: [String: Set<OSLogEntryLog.Level>] = [:]
    
    private var logStore: OSLogStore?
    private var pollTimer: Timer?
    private var lastPollDate: Date?
    private let updateInterval: TimeInterval = 0.5
    
    // ServiceProtocol requirements
    var continuations: [ServiceContinuation.Continuation] = []
    
    var currentServiceState: ServiceState<LogServiceData> {
        return .loaded(LogServiceData(logEntries: logEntries))
    }
    
    var mostRecentLoadedServiceState: ServiceState<LogServiceData>? {
        return currentServiceState
    }
    
    init() {
        setupLogStore()
        loadCategories()
        startObservingLogs()
    }
    
    private func setupLogStore() {
        do {
            logStore = try OSLogStore(scope: .currentProcessIdentifier)
        } catch {
            print("Failed to create log store: \(error)")
        }
    }
    
    private func loadCategories() {
        guard let url = Bundle.main.url(forResource: "LoggerSettings", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let categoriesDict = plist["categories"] as? [String: Bool] else {
            return
        }
        
        selectedCategories = Set(categoriesDict.keys.filter { categoriesDict[$0] == true })
        // Initialize category log levels with all levels selected
        for category in selectedCategories {
            categoryLogLevels[category] = [.debug, .info, .notice, .error, .fault]
        }
    }
    
    private func startObservingLogs() {
        lastPollDate = Date()
        pollTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.pollLogs()
        }
    }
    
    private func pollLogs() {
        guard !isPaused,
              let logStore = logStore,
              let lastDate = lastPollDate else {
            return
        }
        
        do {
            let entries = try logStore.getEntries(matching: nil)
            let entriesArray = Array(entries)
            lastPollDate = Date()
            
            let newEntries = entriesArray.compactMap { entry -> LogEntry? in
                guard let logEntry = entry as? OSLogEntryLog,
                      logEntry.date >= lastDate else {
                    return nil
                }
                
                let entry = LogEntry(
                    timestamp: logEntry.date,
                    level: logEntry.level,
                    category: logEntry.category,
                    subsystem: logEntry.subsystem,
                    message: logEntry.composedMessage
                )
                
                return shouldShowEntry(entry) ? entry : nil
            }
            
            DispatchQueue.main.async {
                self.logEntries.append(contentsOf: newEntries)
                self.updateSubscribers()
            }
        } catch {
            print("Failed to poll logs: \(error)")
        }
    }
    
    private func shouldShowEntry(_ entry: LogEntry) -> Bool {
        // Check category filter
        if !selectedCategories.isEmpty && !selectedCategories.contains(entry.category) {
            return false
        }
        
        // Check category-specific log levels
        if let categoryLevels = categoryLogLevels[entry.category],
           !categoryLevels.contains(entry.level) {
            return false
        }
        
        // Check global log level
        if !selectedLogLevels.contains(entry.level) {
            return false
        }
        
        // Check search text
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            return entry.message.lowercased().contains(searchLower) ||
                   entry.category.lowercased().contains(searchLower) ||
                   entry.subsystem.lowercased().contains(searchLower)
        }
        
        return true
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
        updateSubscribers()
    }
    
    func clearLogs() {
        logEntries.removeAll()
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
    
    // ServiceProtocol requirement
    func load() {
        updateSubscribers()
    }
    
    deinit {
        pollTimer?.invalidate()
    }
}
