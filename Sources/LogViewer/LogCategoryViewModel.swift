//
//  LogCategoryViewModel.swift
//  LogViewer
//
//  Created by ploden on 7/24/25.
//

import Foundation
import OSLog
import SwiftUI

public class LogCategoryViewModel: ObservableObject, Identifiable {
    private(set) var category: LogCategory
    @Published var logLevelsWithSelectionStates: [LogLevelWithSelectionState]
    @Published var isExpanded: Bool = false
    @Published var isSelected: Bool = true
    
    private let logger = Logger(subsystem: "com.logviewer.app", category: "UI")
    
    public var id: String { category.category }
    
    public init(category: LogCategory) {
        self.category = category
        self.logLevelsWithSelectionStates = [.debug, .info, .notice, .error, .fault].compactMap({ level in
            LogLevelWithSelectionState(logLevel: level, isSelected: true)
        })
    }
}
