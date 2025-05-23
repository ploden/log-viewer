import Foundation
import OSLog
import SwiftUI

@MainActor
class LogViewModel: ObservableObject {
    @Published private(set) var logEntries: [LogEntry] = []
    @Published private(set) var isPaused: Bool = false
    @Published var searchText: String = ""
    @Published private(set) var selectedCategories: Set<String> = []
    @Published private(set) var allAvailableCategories: Set<String> = []
    @Published private(set) var selectedLevels: Set<OSLogEntryLog.Level> = []
    
    private var logService: LogService
    private let logger = Logger(subsystem: "com.logviewer.app", category: "UI")
    
    init(logService: LogService) {
        self.logService = logService
        
        // Initial values
        logEntries = logService.getLogEntries()
        isPaused = logService.getIsPaused()
        searchText = logService.getSearchText()
        selectedCategories = logService.getSelectedCategories()
        selectedLevels = logService.getSelectedLogLevels()
        allAvailableCategories = logService.getAllAvailableCategories()
        
        logger.info("LogViewModel initialized with \(self.logEntries.count) log entries")
        
        // Subscribe to updates using ServiceProtocol
        Task {
            for await state in self.logService.subscribe() {
                if case .loaded(let data) = state {
                    self.logEntries = data.logEntries
                    self.isPaused = self.logService.getIsPaused()
                    self.searchText = self.logService.getSearchText()
                    self.selectedCategories = self.logService.getSelectedCategories()
                    self.selectedLevels = self.logService.getSelectedLogLevels()
                    self.allAvailableCategories = self.logService.getAllAvailableCategories()
                }
            }
        }
    }
    
    func togglePause() {
        logger.info("User toggled pause state from \(self.isPaused) to \(!self.isPaused)")
        logService.togglePause()
    }
    
    func clearLogs() {
        logger.notice("User cleared all logs (had \(self.logEntries.count) entries)")
        logService.clearLogs()
    }
    
    func getCategoryLogLevels(_ category: String) -> Set<OSLogEntryLog.Level> {
        return logService.getCategoryLogLevels(category)
    }
    
    func setCategoryLogLevel(_ category: String, level: OSLogEntryLog.Level, isSelected: Bool) {
        logger.info("User \(isSelected ? "enabled" : "disabled") level \(level.rawValue) for category '\(category)'")
        logService.setCategoryLogLevel(category, level: level, isSelected: isSelected)
    }
    
    func setSelectedLevels(_ levels: Set<OSLogEntryLog.Level>) {
        let levelStrings = levels.map { String($0.rawValue) }.joined(separator: ", ")
        logger.info("User updated global log levels to: [\(levelStrings)]")
        logService.setSelectedLogLevels(levels)
    }
    
    func setSelectedCategories(_ categories: Set<String>) {
        let categoryList = categories.sorted().joined(separator: ", ")
        logger.info("User updated selected categories to: [\(categoryList)]")
        logService.setSelectedCategories(categories)
    }
    
    func updateSearchText(_ text: String) {
        if text.isEmpty {
            logger.info("User cleared search text")
        } else {
            logger.info("User updated search text to: '\(text)'")
        }
        logService.setSearchText(text)
    }
    
    func setGlobalLogLevel(_ level: OSLogEntryLog.Level, isSelected: Bool) {
        logger.notice("User \(isSelected ? "enabled" : "disabled") global log level \(level.rawValue) - cascading to all categories")
        
        // Update the global selected levels
        var levels = selectedLevels
        if isSelected {
            levels.insert(level)
        } else {
            levels.remove(level)
        }
        setSelectedLevels(levels)
        
        // Update the same level for all categories
        for category in selectedCategories {
            setCategoryLogLevel(category, level: level, isSelected: isSelected)
        }
    }
    
    func createTestLog() {
        logger.notice("TEST: User clicked test log button in LogViewModel")
        logService.testLogStatement()
    }
}

extension OSLogEntryLog.Level: CaseIterable {
    public static var allCases: [OSLogEntryLog.Level] {
        [.debug, .info, .notice, .error, .fault]
    }
} 
