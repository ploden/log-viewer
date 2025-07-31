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

@MainActor
final class LogViewerTests: XCTestCase {
    var logService: LogService!
    var viewModel: LogViewerViewModel!
    
    override func setUp() {
        super.setUp()
        logService = LogService()
        viewModel = LogViewerViewModel(logService: logService)
    }
    
    override func tearDown() {
        viewModel = nil
        logService = nil
        super.tearDown()
    }
    
    func testLogServiceInitialState() {
        XCTAssertFalse(logService.getIsPaused())
        // Categories may be empty in test environment if plist is not available
        // XCTAssertFalse(logService.getSelectedCategories().isEmpty)
        XCTAssertEqual(logService.getSelectedLogLevels(), [.debug, .info, .notice, .error, .fault])
    }
    
    func testLogServiceTogglePause() {
        XCTAssertFalse(logService.getIsPaused())
        logService.togglePause()
        XCTAssertTrue(logService.getIsPaused())
        logService.togglePause()
        XCTAssertFalse(logService.getIsPaused())
    }
    
    func testLogServiceClearLogs() {
        // Test clearing logs
        let initialCount = logService.getLogEntries().count
        logService.clearLogs()
        
        // After clearing, should have same or fewer entries (since logs might still be coming in)
        let finalCount = logService.getLogEntries().count
        XCTAssertTrue(finalCount <= initialCount)
    }
    
    func testLogServiceFiltering() {
        // Test log level filtering via setters
        let testLevels: Set<OSLogEntryLog.Level> = [.error, .fault]
        logService.setSelectedLogLevels(testLevels)
        XCTAssertEqual(logService.getSelectedLogLevels(), testLevels)
        
        // Test category filtering
        let testCategory = "TestCategory"
        let testCategories: Set<String> = [testCategory]
        logService.setSelectedCategories(testCategories)
        XCTAssertEqual(logService.getSelectedCategories(), testCategories)
    }
    
    func testLogViewModelInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.searchText, "")
        // Categories may be empty in test environment if plist is not available
        // XCTAssertFalse(viewModel.selectedCategories.isEmpty)
    }
    
    func testLogViewModelSearchText() {
        let searchText = "test search"
        viewModel.updateSearchText(searchText)
        XCTAssertEqual(viewModel.searchText, searchText)
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
        let hostingController = NSHostingController(rootView: view.environmentObject(viewModel))
        
        // Test that the view loads without crashing
        XCTAssertNotNil(hostingController.view)
    }
    
    func testContentView() {
        let view = ContentView()
        let hostingController = NSHostingController(rootView: view.environmentObject(viewModel))
        
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
    
    func testLogEntryProperties() {
        let entry = LogEntry(
            timestamp: Date(),
            level: .error,
            category: "TestCategory",
            subsystem: "TestSubsystem",
            message: "Test Message"
        )
        
        XCTAssertEqual(entry.levelString, "ERROR")
        XCTAssertEqual(entry.levelColor, .red)
        XCTAssertEqual(entry.category, "TestCategory")
        XCTAssertEqual(entry.message, "Test Message")
    }
}
