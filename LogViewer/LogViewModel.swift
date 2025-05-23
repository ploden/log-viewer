import Foundation
import OSLog
import SwiftUI

@MainActor
class LogViewModel: ObservableObject {
    @Published private(set) var logEntries: [LogEntry] = []
    @Published private(set) var isPaused: Bool = false
    @Published var searchText: String = ""
    @Published private(set) var selectedCategories: Set<String> = []
    @Published private(set) var selectedLevels: Set<OSLogEntryLog.Level> = []
    
    private var logService: LogService
    
    init(logService: LogService) {
        self.logService = logService
        
        // Initial values
        logEntries = logService.getLogEntries()
        isPaused = logService.getIsPaused()
        searchText = logService.getSearchText()
        selectedCategories = logService.getSelectedCategories()
        selectedLevels = logService.getSelectedLogLevels()
        
        // Subscribe to updates using ServiceProtocol
        Task {
            for await state in self.logService.subscribe() {
                if case .loaded(let data) = state {
                    self.logEntries = data.logEntries
                    self.isPaused = self.logService.getIsPaused()
                    self.searchText = self.logService.getSearchText()
                    self.selectedCategories = self.logService.getSelectedCategories()
                    self.selectedLevels = self.logService.getSelectedLogLevels()
                }
            }
        }
    }
    
    func togglePause() {
        logService.togglePause()
    }
    
    func clearLogs() {
        logService.clearLogs()
    }
    
    func getCategoryLogLevels(_ category: String) -> Set<OSLogEntryLog.Level> {
        return logService.getCategoryLogLevels(category)
    }
    
    func setCategoryLogLevel(_ category: String, level: OSLogEntryLog.Level, isSelected: Bool) {
        logService.setCategoryLogLevel(category, level: level, isSelected: isSelected)
    }
    
    func setSelectedLevels(_ levels: Set<OSLogEntryLog.Level>) {
        logService.setSelectedLogLevels(levels)
    }
    
    func setSelectedCategories(_ categories: Set<String>) {
        logService.setSelectedCategories(categories)
    }
    
    func updateSearchText(_ text: String) {
        logService.setSearchText(text)
    }
}

extension OSLogEntryLog.Level: CaseIterable {
    public static var allCases: [OSLogEntryLog.Level] {
        [.debug, .info, .notice, .error, .fault]
    }
} 
