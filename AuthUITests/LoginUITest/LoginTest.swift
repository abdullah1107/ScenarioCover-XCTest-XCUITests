//
//  LoginTest.swift
//  AuthenticationSwiftUIUITests
//
//  End-to-end checks of the login flow against the real https://dummyjson.com/auth/login API.
//

import XCTest

final class LoginTest: BaseXCTestSetup {

    func testLoginWithInvalidCredentials() {
        Login.LoginScreen()
            .tapUserTextField("Mamun")
            .tapPasswordTextField("dfuiu&")
            .tapLoginButton()
            .assert(\.loginFailedAlertToastShown, "Failed-login toast was not shown")
    }

    func testInvalidLoginStaysOnLoginScreen() {
        let login = Login.LoginScreen()
            .tapUserTextField("not-a-user")
            .tapPasswordTextField("wrong-password")
            .tapLoginButton()
        _ = login.loginFailedAlertToast
        XCTAssertFalse(DashBoard.ProductScreen.isShownQuickly, "Dashboard must not appear after a failed login")
    }

    func testLoginWithValidCredentials() {
        Login.LoginScreen()
            .tapUserTextField("emilys")
            .tapPasswordTextField("emilyspass")
            .tapLoginButtonSuccess()
            .assertDisplayed(DashBoard.ProductScreen())
    }
}
