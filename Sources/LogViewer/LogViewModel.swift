import Foundation
import OSLog
import SwiftUI

@MainActor
public class LogViewModel: ObservableObject {
    @Published private(set) var allLogEntries: [LogEntry] = []
    @Published private(set) var isPaused: Bool = false
    @Published var searchText: String = "" {
        didSet {
            updateFilteredEntries()
        }
    }
    @Published private(set) var selectedCategories: Set<String> = [] {
        didSet {
            updateFilteredEntries()
        }
    }
    @Published private(set) var allAvailableCategories: Set<String> = []
    @Published private(set) var selectedLevels: Set<OSLogEntryLog.Level> = [] {
        didSet {
            updateFilteredEntries()
        }
    }
    
    @Published private(set) var logEntries: [LogEntry] = []
    
    private var logService: LogService
    private let logger = Logger(subsystem: "com.logviewer.app", category: "UI")
    private var filteringTask: Task<Void, Never>?
    
    public init(logService: LogService) {
        self.logService = logService
        
        // Initial values
        allLogEntries = logService.getLogEntries()
        isPaused = logService.getIsPaused()
        // searchText starts empty - it's UI-only now
        selectedCategories = logService.getSelectedCategories()
        selectedLevels = logService.getSelectedLogLevels()
        allAvailableCategories = logService.getAllAvailableCategories()
        
        // Apply initial filtering
        updateFilteredEntries()
        
        logger.info("LogViewModel initialized with \(self.allLogEntries.count) log entries")
        
        // Subscribe to updates using ServiceProtocol
        Task {
            for await state in self.logService.subscribe() {
                if case .loaded(let data) = state {
                    self.allLogEntries = data.logEntries
                    self.isPaused = self.logService.getIsPaused()
                    // Don't update searchText from service - user controls it directly
                    self.selectedCategories = self.logService.getSelectedCategories()
                    self.selectedLevels = self.logService.getSelectedLogLevels()
                    self.allAvailableCategories = self.logService.getAllAvailableCategories()
                    self.updateFilteredEntries()
                }
            }
        }
    }
    
    deinit {
        filteringTask?.cancel()
    }
    
    private func updateFilteredEntries() {
        // Cancel any existing filtering task
        filteringTask?.cancel()
        
        let currentAllEntries = allLogEntries
        let currentSearchText = searchText
        let currentSelectedCategories = selectedCategories
        let currentSelectedLevels = selectedLevels
        let currentLogEntries = logEntries
        
        // Get category log levels on main thread before moving to background
        let categoryLogLevels = Dictionary(uniqueKeysWithValues: 
            currentSelectedCategories.map { category in
                (category, logService.getCategoryLogLevels(category))
            }
        )
        
        filteringTask = Task {
            // Perform filtering on background thread
            let filtered = await Task.detached {
                return currentAllEntries.filter { entry in
                    // If no categories are selected, show nothing
                    if currentSelectedCategories.isEmpty {
                        return false
                    }
                    
                    // Only show entries from selected categories
                    if !currentSelectedCategories.contains(entry.category) {
                        return false
                    }
                    
                    // Check category-specific log levels
                    let categoryLevels = categoryLogLevels[entry.category] ?? []
                    if !categoryLevels.contains(entry.level) {
                        return false
                    }
                    
                    // Check global log level
                    if !currentSelectedLevels.contains(entry.level) {
                        return false
                    }
                    
                    // Check search text
                    if !currentSearchText.isEmpty {
                        let searchLower = currentSearchText.lowercased()
                        let matches = entry.message.lowercased().contains(searchLower) ||
                                     entry.category.lowercased().contains(searchLower) ||
                                     entry.subsystem.lowercased().contains(searchLower)
                        if !matches {
                            return false
                        }
                    }
                    
                    return true
                }
            }.value
            
            // Only update if results changed and task wasn't cancelled
            if !Task.isCancelled && !arraysEqual(filtered, currentLogEntries) {
                await MainActor.run {
                    self.logEntries = filtered
                }
            }
        }
    }
    
    private func arraysEqual(_ array1: [LogEntry], _ array2: [LogEntry]) -> Bool {
        guard array1.count == array2.count else { return false }
        for i in 0..<array1.count {
            if array1[i].id != array2[i].id {
                return false
            }
        }
        return true
    }
    
    func togglePause() {
        logger.info("User toggled pause state from \(self.isPaused) to \(!self.isPaused)")
        logService.togglePause()
    }
    
    func clearLogs() {
        logger.notice("User cleared all logs (had \(self.allLogEntries.count) entries)")
        logService.clearLogs()
    }
    
    func getCategoryLogLevels(_ category: String) -> Set<OSLogEntryLog.Level> {
        return logService.getCategoryLogLevels(category)
    }
    
    func setCategoryLogLevel(_ category: String, level: OSLogEntryLog.Level, isSelected: Bool) {
        logger.info("User \(isSelected ? "enabled" : "disabled") level \(level.rawValue) for category '\(category)'")
        logService.setCategoryLogLevel(category, level: level, isSelected: isSelected)
        // Trigger re-filtering since category log levels changed
        updateFilteredEntries()
    }
    
    func setSelectedLevels(_ levels: Set<OSLogEntryLog.Level>) {
        let levelStrings = levels.map { String($0.rawValue) }.joined(separator: ", ")
        logger.info("User updated global log levels to: [\(levelStrings)]")
        logService.setSelectedLogLevels(levels)
        selectedLevels = levels  // This will trigger didSet and updateFilteredEntries
    }
    
    func setSelectedCategories(_ categories: Set<String>) {
        let categoryList = categories.sorted().joined(separator: ", ")
        logger.info("User updated selected categories to: [\(categoryList)]")
        logService.setSelectedCategories(categories)
        selectedCategories = categories  // This will trigger didSet and updateFilteredEntries
    }
    
    func updateSearchText(_ text: String) {
        if text.isEmpty {
            logger.info("User cleared search text")
        } else {
            logger.info("User updated search text to: '\(text)'")
        }
        // Don't update service - search text is UI-only now
        searchText = text  // This will trigger didSet and updateFilteredEntries
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

extension OSLogEntryLog.Level: @retroactive CaseIterable {
    public static var allCases: [OSLogEntryLog.Level] {
        [.debug, .info, .notice, .error, .fault]
    }
} 

