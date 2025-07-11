//
//  LogViewerTests.swift
//  LogViewerTests
//
//  Created by ploden on 5/22/25.
//

import XCTest
import SwiftUI
import OSLog
@testable import LogViewer

final class LogViewerTests: XCTestCase {
    var logService: LogService!
    
    override func setUp() {
        super.setUp()
        logService = LogService()
    }
    
    override func tearDown() {
        logService = nil
        super.tearDown()
    }
    
    func testLogServiceInitialState() {
        XCTAssertFalse(logService.isPaused)
        XCTAssertTrue(logService.searchText.isEmpty)
        XCTAssertFalse(logService.selectedCategories.isEmpty)
        XCTAssertEqual(logService.selectedLogLevels, [.debug, .info, .notice, .error, .fault])
    }
    
    func testLogServiceTogglePause() {
        XCTAssertFalse(logService.isPaused)
        logService.togglePause()
        XCTAssertTrue(logService.isPaused)
        logService.togglePause()
        XCTAssertFalse(logService.isPaused)
    }
    
    func testLogServiceClearLogs() {
        // Add some test logs
        let testEntry = LogEntry(
            timestamp: Date(),
            level: .info,
            category: "TestCategory",
            subsystem: "TestSubsystem",
            message: "Test Message"
        )
        logService.logEntries = [testEntry]
        
        XCTAssertFalse(logService.logEntries.isEmpty)
        logService.clearLogs()
        XCTAssertTrue(logService.logEntries.isEmpty)
    }
    
    func testLogServiceFiltering() {
        // Test log level filtering
        logService.selectedLogLevels = [.error, .fault]
        XCTAssertEqual(logService.selectedLogLevels.count, 2)
        XCTAssertTrue(logService.selectedLogLevels.contains(.error))
        XCTAssertTrue(logService.selectedLogLevels.contains(.fault))
        
        // Test category filtering
        let testCategory = "TestCategory"
        logService.selectedCategories = [testCategory]
        XCTAssertEqual(logService.selectedCategories.count, 1)
        XCTAssertTrue(logService.selectedCategories.contains(testCategory))
        
        // Test search text
        logService.searchText = "test"
        XCTAssertEqual(logService.searchText, "test")
    }
    
    func testLogEntryRow() {
        let entry = LogEntry(
            timestamp: Date(),
            level: .info,
            category: "TestCategory",
            subsystem: "TestSubsystem",
            message: "Test Message"
        )
        
        let view = LogEntryRow(entry: entry)
        let hostingController = NSHostingController(rootView: view)
        
        // Test that the view loads without crashing
        XCTAssertNotNil(hostingController.view)
    }
    
    func testSidebarView() {
        let view = SidebarView()
        let hostingController = NSHostingController(rootView: view.environmentObject(logService))
        
        // Test that the view loads without crashing
        XCTAssertNotNil(hostingController.view)
    }
    
    func testContentView() {
        let view = ContentView()
        let hostingController = NSHostingController(rootView: view.environmentObject(logService))
        
        // Test that the view loads without crashing
        XCTAssertNotNil(hostingController.view)
    }
    
    func testOSLogLevelDescription() {
        XCTAssertEqual(OSLogEntryLog.Level.debug.description, "Debug")
        XCTAssertEqual(OSLogEntryLog.Level.info.description, "Info")
        XCTAssertEqual(OSLogEntryLog.Level.notice.description, "Notice")
        XCTAssertEqual(OSLogEntryLog.Level.error.description, "Error")
        XCTAssertEqual(OSLogEntryLog.Level.fault.description, "Fault")
    }
}
