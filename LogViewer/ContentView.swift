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
    @State private var showSidebar = true
    @State private var showSidebarModal = false
    private let logger = Logger(subsystem: "com.logviewer.app", category: "UI")
    
    var body: some View {
        #if os(iOS)
        NavigationView {
            LogView(viewModel: viewModel, showSidebar: $showSidebar)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Filters") {
                            showSidebarModal = true
                        }
                    }
                }
                .sheet(isPresented: $showSidebarModal) {
                    NavigationView {
                        SidebarView()
                            .navigationTitle("Filters")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        showSidebarModal = false
                                    }
                                }
                            }
                    }
                }
        }
        #else
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
        #endif
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
                    #if os(iOS)
                    .toggleStyle(.switch)
                    #endif
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
                                #if os(iOS)
                                .toggleStyle(.switch)
                                #else
                                .toggleStyle(.checkbox)
                                #endif
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
                        #if os(iOS)
                        .toggleStyle(.switch)
                        #endif
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
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
