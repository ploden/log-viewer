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
    private var allAvailableCategories: Set<String> = []
    private var categoryLogLevels: [String: Set<OSLogEntryLog.Level>] = [:]
    
    private var logStore: OSLogStore?
    private var pollTimer: Timer?
    private var lastPollDate: Date?
    private var pollLogsTask: Task<Void, Never>?
    private let updateInterval: TimeInterval = 0.5
    private let logger = Logger(subsystem: "com.logviewer.service", category: "LogService")
    
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
        startObservingLogs()
    }
    
    private func setupLogStore() {
        do {
            logStore = try OSLogStore(scope: .currentProcessIdentifier)
            logger.info("OSLogStore created successfully with currentProcessIdentifier scope")
        } catch {
            logger.error("Failed to create log store: \(error.localizedDescription)")
        }
    }
    
    private func startObservingLogs() {
        lastPollDate = Date().addingTimeInterval(-30.0)
        pollTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.pollLogs()
        }
        logger.info("Started observing logs with \(self.updateInterval)s interval")
    }
    
    private func pollLogs() {
        guard !isPaused,
              let logStore = logStore else {
            return
        }

        guard pollLogsTask == nil else {
            return
        }

        pollLogsTask = Task {
            do {
                // Use the timestamp of the most recent log entry, or last 30 seconds if no entries exist
                let sinceDate = logEntries.last?.timestamp ?? Date().addingTimeInterval(-30.0)
                
                let predicate = NSPredicate(format: "date >= %@", sinceDate as NSDate)
                let entries = try logStore.getEntries(matching: predicate)
                let entriesArray = Array(entries)

                let newEntries = entriesArray.compactMap { entry -> LogEntry? in
                    guard let logEntry = entry as? OSLogEntryLog else {
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
    
    func clearLogs() {
        let previousCount = logEntries.count
        logEntries.removeAll()
        logger.notice("Cleared \(previousCount) log entries")
        updateSubscribers()
    }
    
    func getAllAvailableCategories() -> Set<String> {
        return allAvailableCategories
    }
    
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
