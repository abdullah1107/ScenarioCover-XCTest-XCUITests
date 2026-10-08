//
//  BaseTestCase.swift
//  AuthenticationSwiftUIUITests
//
//  Created by Muhammad Mamun on 9/12/23.
//

import XCTest

class BaseXCTestSetup: XCTestCase {

    /// Override to pass extra launch arguments, e.g. `["--logged-in"]` to skip the login screen.
    var additionalLaunchArguments: [String] { [] }

    override func setUpWithError() throws {
        try super.setUpWithError()
        let app = XCUIApplication()
        
        app.launchArguments.append("--uitesting")
        app.launchArguments.append(contentsOf: additionalLaunchArguments)
        // Put setup code here. This method is called before the invocation of each test method in the class.
        app.launch()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    override func tearDownWithError() throws {
        try? super.tearDownWithError()
    }
}

extension XCUIApplication {
    func uninstall() {
        let timeout = TimeInterval(5)
        let springboard = XCUIApplication(bundleIdentifier: "com.appsQube.AuthUI")
        
        let appName = springboard.icons.softMatching(substring: "AuthUI")[0].label
        
        let appIcon = springboard.icons[appName].firstMatch
        if appIcon.waitForExistence(timeout: timeout) {
            appIcon.press(forDuration: 2)
        } else {
            XCTFail("Failed to find app icon named \(appName)")
        }
        
        let removeAppButton = springboard.buttons["Remove App"]
        if removeAppButton.waitForExistence(timeout: timeout) {
            removeAppButton.tap()
        } else {
            XCTFail("Failed to find 'Remove App'")
        }
        
        let deleteAppButton = springboard.alerts.buttons["Delete App"]
        if deleteAppButton.waitForExistence(timeout: timeout) {
            deleteAppButton.tap()
        } else {
            XCTFail("Failed to find 'Delete App'")
        }
        
        let finalDeleteButton = springboard.alerts.buttons["Delete"]
        if finalDeleteButton.waitForExistence(timeout: timeout) {
            finalDeleteButton.tap()
        } else {
            XCTFail("Failed to find 'Delete'")
        }
    }
}
