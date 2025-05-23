//
//  ContentView.swift
//  LogViewer
//
//  Created by ploden on 5/22/25.
//

import SwiftUI
import OSLog

struct ContentView: View {
    @EnvironmentObject private var viewModel: LogViewModel
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            VStack(spacing: 0) {
                toolbar
                LogView(viewModel: viewModel)
            }
        }
    }
    
    private var toolbar: some View {
        HStack {
            Button(action: { viewModel.togglePause() }) {
                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
            }
            .buttonStyle(.borderless)
            
            Button(action: { viewModel.clearLogs() }) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
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
    
    var body: some View {
        List {
            Section("Global Log Levels") {
                ForEach([OSLogEntryLog.Level.debug, .info, .notice, .error, .fault], id: \.self) { level in
                    Toggle(level.description, isOn: Binding(
                        get: { viewModel.selectedLevels.contains(level) },
                        set: { isSelected in
                            var levels = viewModel.selectedLevels
                            if isSelected {
                                levels.insert(level)
                            } else {
                                levels.remove(level)
                            }
                            viewModel.setSelectedLevels(levels)
                        }
                    ))
                }
            }
            
            Section("Categories") {
                ForEach(Array(viewModel.selectedCategories.sorted()), id: \.self) { category in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedCategories.contains(category) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedCategories.insert(category)
                                } else {
                                    expandedCategories.remove(category)
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
                                } else {
                                    categories.remove(category)
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
        @unknown default:
            return "Unknown"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LogViewModel(logService: LogService()))
}
