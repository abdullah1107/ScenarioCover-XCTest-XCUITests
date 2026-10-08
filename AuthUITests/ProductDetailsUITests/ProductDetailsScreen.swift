//
//  ProductDetailsScreen.swift
//  AuthUIUITests
//
//  Created by Muhammad Mamun on 11/12/23.
//

import Foundation
import XCTest


extension ProductDetails{
    struct ProductElement: Screen{
        var displayElement: XCUIElement { titleLabel }
        init() {
            waitForScreenDisplay()
        }
    }
}


extension ProductDetails.ProductElement{
    var titleLabel: XCUIElement { app.staticTexts["productDetailsIdentifier"].firstMatch }
    var descriptionLabel: XCUIElement { app.staticTexts["productDescription"].firstMatch }
    var priceLabel: XCUIElement { app.staticTexts["productPrice"].firstMatch }
    var imageCarousel: XCUIElement { app.descendants(matching: .any)["productImageCarousel"].firstMatch }

    var titleText: String {
        titleLabel.waitUntilDisplayed(timeout: 10)
        return titleLabel.label
    }
    var descriptionText: String {
        descriptionLabel.waitUntilDisplayed(timeout: 10)
        return descriptionLabel.label
    }
    var isPriceDisplayed: Bool { priceLabel.waitUntilDisplayed(timeout: 10) }
    var isImageCarouselDisplayed: Bool { imageCarousel.waitUntilDisplayed(timeout: 10) }
}


