//
//  LogViewerApp.swift
//  LogViewer
//
//  Created by ploden on 5/22/25.
//

import SwiftUI
import OSLog

@main
struct LogViewerApp: App {
    private let logService: LogService
    @StateObject private var viewModel: LogViewModel
    
    init() {
        let service = LogService()
        logService = service
        _viewModel = StateObject(wrappedValue: LogViewModel(logService: service))
    }
    
    var body: some Scene {
        WindowGroup("LogViewer", id: "main-window") {
            ContentView()
                .environmentObject(viewModel)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        #endif
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
        
        // Additional window group for side-by-side demo functionality
        WindowGroup("LogViewer Demo", id: "demo-window") {
            ContentView()
                .environmentObject(viewModel)
                .navigationTitle("LogViewer Demo")
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        #endif
        .handlesExternalEvents(matching: Set(arrayLiteral: "demo"))
    }
}

