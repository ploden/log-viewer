//
//  ContentView.swift
//  LogViewer
//
//  Created by ploden on 5/22/25.
//

import SwiftUI
import OSLog

public struct ContentView: View {
    @EnvironmentObject private var viewModel: LogViewModel
    @State private var showSidebar = true
    private let logger = Logger(subsystem: "com.logviewer.app", category: "UI")
    
    public init() {}

    public var body: some View {
        NavigationSplitView {
            if showSidebar {
                SidebarView()
            }
        } detail: {
            LogView(viewModel: viewModel, showSidebar: $showSidebar)
        }
        .onChange(of: showSidebar) { oldValue, newValue in
            logger.info("Sidebar visibility changed from \(oldValue) to \(newValue)")
        }
    }
}

struct CategoryLogLevels: Identifiable {
    let id: String
    let category: String
    var selectedLevels: Set<OSLogEntryLog.Level>
}

struct SidebarView: View {
    @EnvironmentObject private var viewModel: LogViewModel
    @State private var expandedCategories: Set<String> = []
    private let logger = Logger(subsystem: "com.logviewer.app", category: "UI")
    
    var body: some View {
        List {
            Section("Global Log Levels") {
                ForEach([OSLogEntryLog.Level.debug, .info, .notice, .error, .fault], id: \.self) { level in
                    Toggle(level.description, isOn: Binding(
                        get: { viewModel.selectedLevels.contains(level) },
                        set: { isSelected in
                            viewModel.setGlobalLogLevel(level, isSelected: isSelected)
                        }
                    ))
                }
            }
            
            Section("Categories") {
                ForEach(Array(viewModel.allAvailableCategories.sorted()), id: \.self) { category in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedCategories.contains(category) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedCategories.insert(category)
                                    logger.debug("User expanded category '\(category)'")
                                } else {
                                    expandedCategories.remove(category)
                                    logger.debug("User collapsed category '\(category)'")
                                }
                            }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach([OSLogEntryLog.Level.debug, .info, .notice, .error, .fault], id: \.self) { level in
                                Toggle(level.description, isOn: Binding(
                                    get: { viewModel.getCategoryLogLevels(category).contains(level) },
                                    set: { isSelected in
                                        viewModel.setCategoryLogLevel(category, level: level, isSelected: isSelected)
                                    }
                                ))
                                .toggleStyle(.checkbox)
                            }
                        }
                        .padding(.leading)
                    } label: {
                        Toggle(category, isOn: Binding(
                            get: { viewModel.selectedCategories.contains(category) },
                            set: { isSelected in
                                var categories = viewModel.selectedCategories
                                if isSelected {
                                    categories.insert(category)
                                    logger.info("User enabled category '\(category)'")
                                } else {
                                    categories.remove(category)
                                    logger.info("User disabled category '\(category)'")
                                }
                                viewModel.setSelectedCategories(categories)
                            }
                        ))
                    }
                }
            }
        }
        .listStyle(.sidebar)
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

#Preview {
    ContentView()
        .environmentObject(LogViewModel(logService: LogService()))
}
