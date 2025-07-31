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
    var logViewModel: LogViewerViewModel?
    lazy private var categories: [LogCategory] = {
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
    
    @MainActor
    func showLogWindow() {
        if let window = logWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        if logViewModel == nil {
            let service = LogService()
            self.logViewModel = LogViewerViewModel(logService: service, logCategories: self.categories)
        }
        
        let contentView = LogViewer.ContentView(viewModel: logViewModel!)
        
        let logViewHostingController = NSHostingController(rootView: contentView)
        logViewHostingController.sizingOptions = []
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: true
        )

        window.contentViewController = logViewHostingController
        window.setContentSize(NSSize(width: 800, height: 600))
        window.minSize = NSSize(width: 400, height: 300)
        window.maxSize = NSSize(width: 2000, height: 1500)
        window.isRestorable = true
        window.center()
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        
        if let titlebar = window.standardWindowButton(.closeButton)?.superview {
            titlebar.subviews.first(where: { $0 is NSTextField })?.removeFromSuperview()
            let titleLabel = NSTextField(labelWithString: "Log Viewer")
            titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            titleLabel.textColor = .labelColor
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titlebar.addSubview(titleLabel)
            NSLayoutConstraint.activate([
                titleLabel.centerXAnchor.constraint(equalTo: titlebar.centerXAnchor),
                titleLabel.centerYAnchor.constraint(equalTo: titlebar.centerYAnchor)
            ])
        }
        
        window.setFrameAutosaveName("LogWindow")
        window.delegate = self
        
        self.logWindow = window
        
        DispatchQueue.main.async {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func loadCategories() -> [LogCategory] {
        guard let url = Bundle.main.url(forResource: "LogViewerLoggerSettings", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let categoriesDict = plist["categories"] as? [String: Bool] else {
            print("Failed to load or parse LogViewerLoggerSettings.plist")
            return []
        }
        
        return categoriesDict.keys.sorted().map { category in
            LogCategory(category: category)
        }
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
