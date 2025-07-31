//
//  ContentView.swift
//  LogViewer
//
//  Created by ploden on 5/22/25.
//

import SwiftUI
import OSLog

public struct ContentView: View {
    @StateObject private var viewModel: LogViewerViewModel
    @State private var showSidebar = true
    private let logger = Logger(subsystem: "com.logviewer.app", category: "UI")
    
    public init(viewModel: LogViewerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationSplitView {
            if showSidebar {
                SidebarView(viewModel: self.viewModel)
            }
        } detail: {
            LogViewerView(viewModel: viewModel, showSidebar: $showSidebar)
        }
        .onChange(of: showSidebar) { oldValue, newValue in
            logger.info("Sidebar visibility changed from \(oldValue) to \(newValue)")
        }
    }
}

struct LogLevelToggle: View {
    @ObservedObject var level: LogLevelWithSelectionState
    
    var body: some View {
        Toggle(level.logLevel.description, isOn: $level.isSelected)
    }
}

struct CategoryLogLevels: Identifiable {
    let id: String
    let category: String
    var selectedLevels: Set<OSLogEntryLog.Level>
}

struct SidebarView: View {
    private var viewModel: LogViewerViewModel
    private let logger = Logger(subsystem: "com.logviewer.app", category: "UI")

    public init(viewModel: LogViewerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            Section("Global Log Levels") {
                ForEach(viewModel.globalLogLevelsWithSelectionStates, id: \.id) { levelWithState in
                    LogLevelToggle(level: levelWithState)
                }
            }
            
            Section("Categories") {
                
            }
        }
        .listStyle(.sidebar)
    }
}

/*
struct CategoryRow: View {
    @ObservedObject var categoryViewModel: LogCategoryViewModel
    let logger: Logger
    
    var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { categoryViewModel.isExpanded },
                set: { isExpanded in
                    categoryViewModel.isExpanded = isExpanded
                    logger.debug("User \(isExpanded ? "expanded" : "collapsed") category '\(categoryViewModel.category.category)'")
                }
            )
        ) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach([OSLogEntryLog.Level.debug, .info, .notice, .error, .fault], id: \.self) { level in
                    Toggle(level.description, isOn: Binding(
                        get: { categoryViewModel.categoryLogLevels[categoryViewModel.category.category]?.contains(level) ?? false },
                        set: { isSelected in
                            var levels = categoryViewModel.categoryLogLevels[categoryViewModel.category.category] ?? []
                            if isSelected {
                                levels.insert(level)
                            } else {
                                levels.remove(level)
                            }
                            categoryViewModel.categoryLogLevels[categoryViewModel.category.category] = levels
                        }
                    ))
                    .toggleStyle(.checkbox)
                }
            }
            .padding(.leading)
        } label: {
            Toggle(categoryViewModel.category.category, isOn: Binding(
                get: { categoryViewModel.isSelected },
                set: { isSelected in
                    categoryViewModel.isSelected = isSelected
                }
            ))
            .toggleStyle(.checkbox)
        }
    }
}
 */

extension OSLogEntryLog.Level {
    var description: String {
        switch self {
        case .debug:
            return "Debug"
        case .info:
            return "Info"
        case .notice:
            return "Notice"
        case .error:
            return "Error"
        case .fault:
            return "Fault"
        case .undefined:
            return "Undefined"
        @unknown default:
            return "Unknown"
        }
    }
}

/*
#Preview {
    ContentView()
}
*/
