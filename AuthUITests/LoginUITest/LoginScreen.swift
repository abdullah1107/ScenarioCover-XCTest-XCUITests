//
//  LoginScreen.swift
//  AuthenticationSwiftUIUITests
//
//  Created by Muhammad Mamun on 9/12/23.
//

import Foundation
import XCTest


extension Login {
    
    struct LoginScreen: Screen {
        var displayElement: XCUIElement { titleLabel }
        init() {
            waitForScreenDisplay(timeout: 10) // splash screen shows for ~3s first
        }
    }
}

fileprivate extension Login.LoginScreen {
    var titleLabel: XCUIElement { app.staticTexts["login"].firstMatch }
    var userNameTextField: XCUIElement { app.textFields["usernameField"].firstMatch }
    var passwordTextField: XCUIElement { app.secureTextFields["passwordField"].firstMatch }
    var loginButton: XCUIElement { app.buttons["loginButton"].firstMatch }
    var loginFailedToast: XCUIElement { app.staticTexts["loginFailedToast"].firstMatch }
}


extension Login.LoginScreen {
    
    @discardableResult
    func tapUserTextField(_ username:String) -> Self {
        userNameTextField.waitUntilDisplayed()
        userNameTextField.tap()
        userNameTextField.typeText(username)
        return self
    }

    @discardableResult
    func tapPasswordTextField(_ password:String) -> Self {
        passwordTextField.waitUntilDisplayed()
        passwordTextField.tap()
        passwordTextField.typeText(password)
        app.buttons["Return"].tap()
        return self
    }
    
    @discardableResult
    func tapLoginButton() -> Self {
        loginButton.waitUntilDisplayed()
        loginButton.tap()
        return self
    }
    
    var loginFailedAlertToastShown: Bool {
        loginFailedToast.waitUntilDisplayed(timeout: 10)
    }

    var loginFailedAlertToast: String {
        loginFailedToast.waitUntilDisplayed(timeout: 10)
        return loginFailedToast.label
    }
    
    @discardableResult
    func tapLoginButtonSuccess() -> DashBoard.ProductScreen {
        loginButton.waitUntilDisplayed()
        loginButton.tap()
        return DashBoard.ProductScreen() // waits up to 10s for the dashboard after the login API responds
    }
}
