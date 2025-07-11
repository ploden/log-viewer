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

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var logWindow: NSWindow?
    var logViewModel: LogViewModel?

    @MainActor
    func showLogWindow() {
        if let window = logWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        if logViewModel == nil {
            let service = LogService()
            self.logViewModel = LogViewModel(logService: service)
        }

        let contentView = LogViewer.ContentView(viewModel: logViewModel!)
        let logViewHostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.contentViewController = logViewHostingController
        window.center()
        window.title = "Log Viewer"
        window.setFrameAutosaveName("LogWindow")

        window.delegate = self

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.logWindow = window
    }

}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        if window == logWindow {
            logWindow = nil
            logViewModel = nil
        }
    }
}
