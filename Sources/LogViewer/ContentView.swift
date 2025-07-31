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
                ForEach(viewModel.categoryViewModels, id: \.id) { category in
                    CategoryRow(categoryViewModel: category)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

struct CategoryRow: View {
    @ObservedObject var categoryViewModel: LogCategoryViewModel
    let logger: Logger = Logger(subsystem: "com.logviewer.app", category: "UI")
    
    @State private var levelStates: [OSLogEntryLog.Level: LogLevelWithSelectionState] = [:]
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $categoryViewModel.isExpanded
        ) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(categoryViewModel.logLevelsWithSelectionStates, id: \.id) { levelWithState in
                    LogLevelToggle(level: levelWithState)
                }
            }
            .padding(.leading)
        } label: {
            Toggle(categoryViewModel.category.category, isOn: $categoryViewModel.isSelected)
            .toggleStyle(.checkbox)
        }
    }
}

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
