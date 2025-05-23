//
//  LogViewerUITests.swift
//  LogViewerUITests
//
//  Created by ploden on 5/22/25.
//

import XCTest

final class LogViewerUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testBasicUIElements() {
        // Test search field exists
        let searchField = app.textFields["Search logs..."]
        XCTAssertTrue(searchField.exists)
        
        // Test play/pause button exists
        let playPauseButton = app.buttons["play.fill"]
        XCTAssertTrue(playPauseButton.exists)
        
        // Test clear button exists
        let clearButton = app.buttons["trash"]
        XCTAssertTrue(clearButton.exists)
    }
    
    func testSearchFunctionality() {
        let searchField = app.textFields["Search logs..."]
        searchField.tap()
        searchField.typeText("test")
        XCTAssertEqual(searchField.value as? String, "test")
    }
    
    func testPlayPauseButton() {
        let playPauseButton = app.buttons["play.fill"]
        playPauseButton.tap()
        XCTAssertTrue(app.buttons["pause.fill"].exists)
        app.buttons["pause.fill"].tap()
        XCTAssertTrue(app.buttons["play.fill"].exists)
    }
    
    func testSidebarCategories() {
        // Test that sidebar exists
        let sidebar = app.outlines.firstMatch
        XCTAssertTrue(sidebar.exists)
        
        // Test that log levels section exists
        let logLevelsSection = app.staticTexts["Log Levels"]
        XCTAssertTrue(logLevelsSection.exists)
        
        // Test that categories section exists
        let categoriesSection = app.staticTexts["Categories"]
        XCTAssertTrue(categoriesSection.exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
