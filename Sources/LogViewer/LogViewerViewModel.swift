import Foundation
import OSLog
import SwiftUI

public class LogLevelWithSelectionState: ObservableObject, Identifiable {
    public init(logLevel: OSLogEntryLog.Level, isSelected: Bool) {
        self.logLevel = logLevel
        self.isSelected = isSelected
    }
    
    @Published var logLevel: OSLogEntryLog.Level
    @Published var isSelected: Bool
}

@MainActor
public class LogViewerViewModel: ObservableObject {
    @Published var globalLogLevelsWithSelectionStates: [LogLevelWithSelectionState]
    private var allLogEntries: [LogEntry] = []
    @Published var isPaused: Bool = false
    @Published var searchText: String = "" {
        didSet {
            updateFilteredEntries()
        }
    }
    
    @Published var logEntries: [LogEntry] = []
    
    var logService: LogService
    @Published var categoryViewModels: [LogCategoryViewModel]
    private let logger = Logger(subsystem: "com.logviewer.app", category: "UI")
    private var filteringTask: Task<Void, Never>?
    
    public init(logService: LogService, logCategories: [LogCategory]) {
        self.logService = logService
        self.categoryViewModels = logCategories.compactMap { category in
            LogCategoryViewModel(category: category)
        }
        
        self.globalLogLevelsWithSelectionStates = [.debug, .info, .notice, .error, .fault].compactMap({ level in
            LogLevelWithSelectionState(logLevel: level, isSelected: true)
        })
        
        updateFilteredEntries()
        
        logger.info("LogViewModel initialized with \(self.allLogEntries.count) log entries")
        
        Task {
            for await state in self.logService.subscribe() {
                if case .loaded(let data) = state {
                    self.allLogEntries = data.logEntries
                    self.updateFilteredEntries()
                }
            }
        }
    }
    
    deinit {
        filteringTask?.cancel()
    }
    
    private func updateFilteredEntries() {
        filteringTask?.cancel()
        
        let currentAllEntries = allLogEntries
        let currentSearchText = searchText
        let selectedLevels = globalLogLevelsWithSelectionStates.filter { $0.isSelected == true }.compactMap { $0.logLevel }
        let currentSelectedLevels = selectedLevels
        let currentLogEntries = logEntries
        
        let selectedCategories = Set(categoryViewModels.filter { $0.isSelected }.map { $0.category.category })
        
        filteringTask = Task {
            let filtered = await Task.detached {
                return currentAllEntries.filter { entry in
                    if !selectedCategories.contains(entry.category) {
                        return false
                    }
                    
                    if !currentSelectedLevels.contains(entry.level) {
                        return false
                    }
                    
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
    
    func clearLogs() {
        logger.notice("User cleared all logs (had \(self.allLogEntries.count) entries)")
        logService.clearLogs()
    }
    
    func updateSearchText(_ text: String) {
        if text.isEmpty {
            logger.info("User cleared search text")
        } else {
            logger.info("User updated search text to: '\(text)'")
        }
        searchText = text
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

