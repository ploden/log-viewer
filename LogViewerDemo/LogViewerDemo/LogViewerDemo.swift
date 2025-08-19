//
//  LogViewerDemo.swift
//  LogViewer
//
//  Created by ploden on 5/22/25.
//

import SwiftUI
import OSLog
import LogViewer

@main
struct LogViewerDemo: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .singleWindowList) {
                Button("Show Log") {
                    appDelegate.showLogWindow()
                }
                .keyboardShortcut("L", modifiers: [.command, .shift])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject, HasLogWindow {
    var logWindow: NSWindow?
    var logViewModel: LogViewerViewModel?
    lazy internal var categories: [LogCategory] = {
        return loadCategories()
    }()
    
    enum LogViewerError: Error {
        case failedToLoadCategories
        
        var localizedDescription: String {
            switch self {
            case .failedToLoadCategories:
                return "Failed to load or parse LogViewerLoggerSettings.plist"
            }
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        showLogWindow()
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowDidClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        if window == logWindow {
            logWindow = nil
            logViewModel = nil
        }
    }
}
