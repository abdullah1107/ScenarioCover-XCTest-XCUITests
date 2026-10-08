//
//  ProductDetailsAPITests.swift
//  AuthUITests
//
//  Covers GET https://dummyjson.com/products/{id} and ProductDetailsViewModel.
//

import XCTest
import Combine
@testable import AuthUI

final class ProductDetailsStubbedTests: XCTestCase {

    private var service: ProductDetailsService!

    override func setUp() {
        super.setUp()
        service = ProductDetailsService(urlSession: MockURLProtocol.makeSession())
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
        service = nil
        super.tearDown()
    }

    private let fullJSON = """
    {"id":1,"title":"Essence Mascara Lash Princess",
     "description":"A popular mascara known for its volumizing and lengthening effects.",
     "category":"beauty","price":9.99,"discountPercentage":10,"rating":4.94,"stock":5,
     "tags":["beauty","mascara"],"brand":"Essence","sku":"BEA-ESS-ESS-001","weight":2,
     "dimensions":{"width":23.17,"height":14.43,"depth":28.01},
     "warrantyInformation":"1 week warranty","shippingInformation":"Ships in 3-5 business days",
     "availabilityStatus":"Low Stock",
     "reviews":[{"rating":3,"comment":"Would not recommend!","date":"2025-04-30T09:41:02.053Z",
                 "reviewerName":"Eleanor Collins","reviewerEmail":"eleanor.collins@x.dummyjson.com"}],
     "returnPolicy":"No return policy","minimumOrderQuantity":24,
     "meta":{"createdAt":"2025-04-30T09:41:02.053Z","updatedAt":"2025-04-30T09:41:02.053Z",
             "barcode":"5784719087687","qrCode":"https://cdn.dummyjson.com/public/qr-code.png"},
     "images":["https://cdn.dummyjson.com/1/1.webp","https://cdn.dummyjson.com/1/2.webp"],
     "thumbnail":"https://cdn.dummyjson.com/1/thumbnail.webp"}
    """

    private func stub(status: Int = 200, body: String) {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.http(request.url, status: status), Data(body.utf8))
        }
    }

    func testURLIsProductsSlashId() {
        XCTAssertEqual(ProductDetailsService.makeURL(baseURL: "https://dummyjson.com", id: 7)?.absoluteString,
                       "https://dummyjson.com/products/7")
    }

    func testRequestIsGETToProductEndpoint() throws {
        var captured: URLRequest?
        MockURLProtocol.handler = { request in
            captured = request
            return (MockURLProtocol.http(request.url, status: 200), Data(self.fullJSON.utf8))
        }
        _ = try XCTUnwrap(awaitResult(service.fetchProduct(id: 1))?.get())
        XCTAssertEqual(captured?.httpMethod, "GET")
        XCTAssertEqual(captured?.url?.absoluteString, "https://dummyjson.com/products/1")
    }

    func testDecodesFullPayload() throws {
        stub(body: fullJSON)
        let p = try XCTUnwrap(awaitResult(service.fetchProduct(id: 1))?.get())
        XCTAssertEqual(p.title, "Essence Mascara Lash Princess")
        XCTAssertFalse(p.description.isEmpty)
        XCTAssertEqual(p.images.count, 2)
        XCTAssertEqual(p.tags, ["beauty", "mascara"])
        XCTAssertEqual(p.dimensions?.width ?? 0, 23.17, accuracy: 0.001)
        XCTAssertEqual(p.reviews.first?.reviewerName, "Eleanor Collins")
        XCTAssertEqual(p.meta?.barcode, "5784719087687")
        XCTAssertEqual(p.minimumOrderQuantity, 24)
    }

    func testDecodesMinimalPayloadWithDefaults() throws {
        stub(body: #"{"id":3,"title":"Bare","price":5}"#)
        let p = try XCTUnwrap(awaitResult(service.fetchProduct(id: 3))?.get())
        XCTAssertEqual(p.description, "")
        XCTAssertTrue(p.images.isEmpty)
        XCTAssertTrue(p.reviews.isEmpty)
        XCTAssertNil(p.brand)
    }

    func testNotFoundMapsTo404Error() {
        stub(status: 404, body: #"{"message":"Product with id '999' not found"}"#)
        guard case .failure(let error)? = awaitResult(service.fetchProduct(id: 999)) else { return XCTFail("Expected failure") }
        XCTAssertEqual(error, .notFound)
    }

    func testServerErrorAndBadJSON() {
        stub(status: 500, body: "")
        guard case .failure(let e1)? = awaitResult(service.fetchProduct(id: 1)) else { return XCTFail("Expected failure") }
        XCTAssertEqual(e1, .requestFailed)

        stub(body: "nope")
        guard case .failure(let e2)? = awaitResult(service.fetchProduct(id: 1)) else { return XCTFail("Expected failure") }
        XCTAssertEqual(e2, .decodeFailed)
    }

    // MARK: View model

    private let seed = Product(id: 1, title: "List Title", description: "List description", price: 100,
                               discountPercentage: 0, thumbnail: "https://example.com/t.png")

    private func loadAndWait(_ vm: ProductDetailsViewModel) {
        vm.load()
        _ = awaitResult(vm.$state.filter { $0.isFinished })
    }

    func testViewModelStartsWithListItemData() {
        let vm = ProductDetailsViewModel(product: seed, service: service)
        XCTAssertEqual(vm.state, .idle)
        XCTAssertEqual(vm.detail.title, "List Title")
        XCTAssertEqual(vm.imageURLs.map(\.absoluteString), ["https://example.com/t.png"], "Falls back to thumbnail")
    }

    func testViewModelLoadsDetailFromAPI() {
        stub(body: fullJSON)
        let vm = ProductDetailsViewModel(product: seed, service: service)
        loadAndWait(vm)
        XCTAssertEqual(vm.state, .loaded)
        XCTAssertEqual(vm.detail.title, "Essence Mascara Lash Princess")
        XCTAssertEqual(vm.imageURLs.count, 2)
        XCTAssertEqual(vm.availabilityText, "Low Stock (5 left)")
        XCTAssertTrue(vm.infoRows.contains { $0.label == "Brand" && $0.value == "Essence" })
        XCTAssertTrue(vm.infoRows.contains { $0.label == "Warranty" })
    }

    func testViewModelKeepsListDataOnFailure() {
        stub(status: 500, body: "")
        let vm = ProductDetailsViewModel(product: seed, service: service)
        loadAndWait(vm)
        guard case .failed = vm.state else { return XCTFail("Expected failed state, got \(vm.state)") }
        XCTAssertEqual(vm.detail.title, "List Title")
    }

    func testPriceFormatting() {
        let vm = ProductDetailsViewModel(detail: ProductDetail(id: 1, title: "x", price: 200, discountPercentage: 25), service: service)
        XCTAssertTrue(vm.hasDiscount)
        XCTAssertEqual(vm.discountedPrice, 150, accuracy: 0.001)
        XCTAssertEqual(vm.priceText, "$150.00")
        XCTAssertEqual(vm.originalPriceText, "$200.00")
        XCTAssertEqual(vm.discountText, "-25%")
    }
}

/// Calls the real https://dummyjson.com/products/{id}. Needs internet access.
final class ProductDetailsLiveTests: XCTestCase {

    func testLiveProductDetailsIncludeImagesAndDescription() throws {
        let p = try XCTUnwrap(awaitResult(ProductDetailsService().fetchProduct(id: 1), timeout: 20)?.get())
        XCTAssertEqual(p.id, 1)
        XCTAssertFalse(p.title.isEmpty)
        XCTAssertFalse(p.description.isEmpty)
        XCTAssertFalse(p.images.isEmpty)
        XCTAssertGreaterThan(p.price, 0)
        XCTAssertFalse(p.thumbnail.isEmpty)
    }

    func testLiveUnknownProductIsNotFound() {
        guard case .failure(let error)? = awaitResult(ProductDetailsService().fetchProduct(id: 999_999), timeout: 20) else {
            return XCTFail("Expected failure")
        }
        XCTAssertEqual(error, .notFound)
    }
}
