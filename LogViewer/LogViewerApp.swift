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
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}
