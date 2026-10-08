//
//  ProductDashBoardTests.swift
//  AuthenticationSwiftUIUITests
//
//  Created by Muhammad Mamun on 10/12/23.
//

import XCTest

/// Launches already logged in ("--logged-in") so these tests don't depend on the login API.
final class ProductDashBoardTests: BaseXCTestSetup {

    override var additionalLaunchArguments: [String] { ["--logged-in"] }

    func testProductDashBoardDisPlay(){
        DashBoard.ProductScreen()
            .assertDisplayed(DashBoard.ProductScreen())
    }

    func testProductListIsPopulated(){
        DashBoard.ProductScreen()
            .assert(\.firstProductCellDisplayed, "No product rows were displayed")
    }

    // The dashboard now loads page 1 from dummyjson (limit=10, skip=0), which contains
    // exactly two "Red ..." products (Red Lipstick, Red Nail Polish).
    func testSearchItemForDisplay(){
        DashBoard.ProductScreen()
            .assertDisplayed(DashBoard.ProductScreen())
            .tapSearchField("Red")
            .assert(\.searchItemFound, equals: 2, "Item is not found as expected")
    }

    func testClickSearchElement(){
        DashBoard.ProductScreen()
            .tapSearchField("Red")
            .tapSearchElementItem()
            .assertDisplayed(ProductDetails.ProductElement())
    }
}

/// Full journey: real login API call, then the product dashboard.
final class LoginToDashBoardFlowTests: BaseXCTestSetup {

    func testLoginThenProductsAreShown(){
        Login.LoginScreen()
            .tapUserTextField("emilys")
            .tapPasswordTextField("emilyspass")
            .tapLoginButtonSuccess()
            .assertDisplayed(DashBoard.ProductScreen())
            .assert(\.firstProductCellDisplayed, "No product rows were displayed after login")
    }
}
