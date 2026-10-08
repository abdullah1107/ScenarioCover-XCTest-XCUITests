//
//  ProductsAPITests.swift
//  AuthUITests
//
//  Covers GET https://dummyjson.com/products?limit=10&skip=10&select=title,price
//   - ProductsAPIStubbedTests: deterministic, no network
//   - ProductsAPILiveTests:    hits the real dummyjson.com endpoint
//

import XCTest
import Combine
@testable import AuthUI

private let productsEndpoint = "https://dummyjson.com/products"

// MARK: - Stubbed (offline)

final class ProductsAPIStubbedTests: XCTestCase {

    private var service: DashBoardProductNetworkServices!

    override func setUp() {
        super.setUp()
        service = DashBoardProductNetworkServices(urlSession: MockURLProtocol.makeSession())
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
        service = nil
        super.tearDown()
    }

    private let selectedFieldsJSON = """
    {"products":[
      {"id":11,"title":"Annibale Colombo Bed","price":1899.99},
      {"id":12,"title":"Annibale Colombo Sofa","price":2499.99},
      {"id":13,"title":"Bedside Table African Cherry","price":299.99}],
     "total":194,"skip":10,"limit":10}
    """

    private let fullProductJSON = """
    {"products":[{"id":1,"title":"iPhone 9","description":"An apple mobile","price":549,
      "discountPercentage":12.96,"rating":4.69,"stock":94,"brand":"Apple","category":"smartphones",
      "thumbnail":"https://cdn.dummyjson.com/1/thumb.jpg","images":["https://cdn.dummyjson.com/1/1.jpg"]}],
     "total":1,"skip":0,"limit":1}
    """

    private func fetch(limit: Int? = 10, skip: Int? = 10, select: String? = "title,price") -> Result<HomeDashBoard, NetworkError>? {
        awaitResult(service.getAllProducts(endpoint: productsEndpoint, limit: limit, skip: skip,
                                           select: select, responseType: HomeDashBoard.self))
    }

    func testRequestURLMatchesExpectedQuery() throws {
        var captured: URLRequest?
        MockURLProtocol.handler = { request in
            captured = request
            return (MockURLProtocol.http(request.url, status: 200), Data(self.selectedFieldsJSON.utf8))
        }
        _ = try fetch()?.get()

        let url = try XCTUnwrap(captured?.url)
        XCTAssertEqual(captured?.httpMethod, "GET")
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "dummyjson.com")
        XCTAssertEqual(url.path, "/products")
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(Dictionary(uniqueKeysWithValues: query.map { ($0.name, $0.value ?? "") }),
                       ["limit": "10", "skip": "10", "select": "title,price"])
    }

    func testMakeURLProducesExactSpecURL() {
        let url = DashBoardProductNetworkServices.makeURL(endpoint: productsEndpoint, limit: 10, skip: 10, select: "title,price")
        XCTAssertEqual(url?.absoluteString, "https://dummyjson.com/products?limit=10&skip=10&select=title,price")
    }

    func testMakeURLDefaultsAndOmitsEmptySelect() {
        XCTAssertEqual(DashBoardProductNetworkServices.makeURL(endpoint: productsEndpoint, limit: nil, skip: nil, select: nil)?.absoluteString,
                       "https://dummyjson.com/products?limit=30&skip=0")
        XCTAssertEqual(DashBoardProductNetworkServices.makeURL(endpoint: productsEndpoint, limit: 5, skip: 0, select: "")?.absoluteString,
                       "https://dummyjson.com/products?limit=5&skip=0")
    }

    func testDecodesSelectedFieldsWithDecimalPrices() throws {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.http(request.url, status: 200), Data(self.selectedFieldsJSON.utf8))
        }
        let page = try XCTUnwrap(fetch()?.get())
        XCTAssertEqual(page.products.count, 3)
        XCTAssertEqual(page.skip, 10)
        XCTAssertEqual(page.limit, 10)
        XCTAssertEqual(page.total, 194)
        XCTAssertEqual(page.products[0].id, 11)
        XCTAssertEqual(page.products[0].title, "Annibale Colombo Bed")
        XCTAssertEqual(page.products[0].price, 1899.99, accuracy: 0.001)
        XCTAssertEqual(page.products[0].description, "", "Fields omitted by `select` fall back to empty values")
    }

    func testStillDecodesFullProductPayload() throws {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.http(request.url, status: 200), Data(self.fullProductJSON.utf8))
        }
        let product = try XCTUnwrap(fetch(limit: 1, skip: 0, select: nil)?.get().products.first)
        XCTAssertEqual(product.title, "iPhone 9")
        XCTAssertEqual(product.price, 549, accuracy: 0.001)
        XCTAssertEqual(product.brand, "Apple")
        XCTAssertEqual(product.images.count, 1)
    }

    func testServerErrorMapsToRequestFailed() {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.http(request.url, status: 500), Data())
        }
        guard case .failure(let error)? = fetch() else { return XCTFail("Expected failure") }
        XCTAssertEqual(error, .requestFailed)
    }

    func testMalformedJSONMapsToDecodeFailed() {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.http(request.url, status: 200), Data("not json".utf8))
        }
        guard case .failure(let error)? = fetch() else { return XCTFail("Expected failure") }
        XCTAssertEqual(error, .decodeFailed)
    }

    func testBundledMockProductsStillDecode() throws {
        // The dashboard currently renders MockData/products.json; make sure the Product model change keeps it valid.
        let dashboard = try XCTUnwrap(MockDataService.shared.loadProducts(), "products.json should decode")
        XCTAssertFalse(dashboard.products.isEmpty)
    }
}

// MARK: - Live (real network)

/// Calls the real https://dummyjson.com/products endpoint. Needs internet access.
final class ProductsAPILiveTests: XCTestCase {

    private var service: DashBoardProductNetworkServices!

    override func setUp() {
        super.setUp()
        service = DashBoardProductNetworkServices()
    }

    func testLiveProductsLimit10Skip10SelectTitlePrice() throws {
        let result = awaitResult(service.getAllProducts(endpoint: productsEndpoint, limit: 10, skip: 10,
                                                        select: "title,price", responseType: HomeDashBoard.self),
                                 timeout: 20)
        let page = try XCTUnwrap(result?.get(), "Products request failed")

        XCTAssertEqual(page.products.count, 10)
        XCTAssertEqual(page.limit, 10)
        XCTAssertEqual(page.skip, 10)
        XCTAssertGreaterThan(page.total, 10)
        for product in page.products {
            XCTAssertFalse(product.title.isEmpty, "Product \(product.id) has empty title")
            XCTAssertGreaterThan(product.price, 0, "Product \(product.id) has no price")
        }
        XCTAssertEqual(Set(page.products.map(\.id)).count, 10, "Product ids should be unique")
    }

    func testLiveNextPageDiffersFromFirstPage() throws {
        func page(skip: Int) throws -> HomeDashBoard {
            try XCTUnwrap(awaitResult(service.getAllProducts(endpoint: productsEndpoint, limit: 10, skip: skip,
                                                             select: "title,price", responseType: HomeDashBoard.self),
                                      timeout: 20)?.get())
        }
        let first = try page(skip: 0)
        let second = try page(skip: 10)
        XCTAssertTrue(Set(first.products.map(\.id)).isDisjoint(with: second.products.map(\.id)))
    }
}
