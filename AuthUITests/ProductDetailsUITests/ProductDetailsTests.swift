//
//  ProductDetailsTests.swift
//  AuthUIUITests
//
//  Created by Muhammad Mamun on 11/12/23.
//

import XCTest

final class ProductDetailsTests: BaseXCTestSetup {

    override var additionalLaunchArguments: [String] { ["--logged-in"] }

    private func openFirstProduct() -> ProductDetails.ProductElement {
        DashBoard.ProductScreen().tapSearchElementItem()
    }

    func testDetailsShowTitleAndDescription() {
        let details = openFirstProduct()
        XCTAssertFalse(details.titleText.isEmpty, "Product title is empty")
        XCTAssertFalse(details.descriptionText.isEmpty, "Product description is empty")
    }

    func testDetailsShowPriceAndImages() {
        let details = openFirstProduct()
        XCTAssertTrue(details.isPriceDisplayed, "Price not displayed")
        XCTAssertTrue(details.isImageCarouselDisplayed, "Image gallery not displayed")
    }

    func testCanNavigateBackToDashboard() {
        let details = openFirstProduct()
        details.goBack(to: DashBoard.ProductScreen.self)
            .assertDisplayed(DashBoard.ProductScreen())
    }
}
