//
//  DashBoardScreen.swift
//  AuthenticationSwiftUIUITests
//
//  Created by Muhammad Mamun on 10/12/23.
//

import Foundation
import XCTest


extension DashBoard {
    
    struct ProductScreen: Screen {
        var displayElement: XCUIElement { titleLabel }
        init() {
            waitForScreenDisplay(timeout: 10)
        }
    }
}

fileprivate extension DashBoard.ProductScreen {
    /// The screen title is `.navigationTitle("Dashboard")`. A large nav title is exposed as the
    /// navigation bar itself (identified by the title), not reliably as a static text, and the
    /// match is case-sensitive.
    static let navTitle = "Dashboard"
    var titleLabel: XCUIElement { app.navigationBars[Self.navTitle].firstMatch }
    var loginSuccessToast: XCUIElement { app.staticTexts["loginSuccessAlert"].firstMatch }
    var searchBarTextField: XCUIElement { app.searchFields["Search Product"] }
    var searchingCells: XCUIElement { app.cells.firstMatch } // .element crashes when several rows match
}


extension DashBoard.ProductScreen {

    /// Non-waiting-heavy check used to prove the dashboard is NOT on screen.
    static var isShownQuickly: Bool {
        XCUIApplication().navigationBars[navTitle].firstMatch.waitForExistence(timeout: 1)
    }

    var firstProductCellDisplayed: Bool {
        app.cells.firstMatch.waitUntilDisplayed(timeout: 10)
    }

    var loginSuccessAlertToast: String {
        loginSuccessToast.waitUntilDisplayed()
        return loginSuccessToast.label
    }
    
    @discardableResult
    func tapSearchField(_ searchItem:String) -> Self {
        searchBarTextField.waitUntilDisplayed()
        searchBarTextField.tap()
        searchBarTextField.typeText(searchItem)
        return self
    }
    
    var searchItemFound: Int {
        searchingCells.waitUntilDisplayed(timeout: 10)
        return app.cells.count
    }
    
    @discardableResult
    func tapSearchElementItem() -> ProductDetails.ProductElement{
        searchingCells.waitUntilDisplayed(timeout: 10)
        app.cells.element(boundBy: 0).tap()
        return ProductDetails.ProductElement()
    }
  
}
