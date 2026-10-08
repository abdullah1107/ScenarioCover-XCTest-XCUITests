//
//  ProductDetailsViewModel.swift
//  AuthUI
//  Created by Muhammad Mamun on 9/12/23.

import Foundation
import Combine

final class ProductDetailsViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)

        var isFinished: Bool {
            switch self {
            case .loaded, .failed: return true
            case .idle, .loading: return false
            }
        }
    }

    @Published private(set) var state: State = .idle
    /// Starts as the list item's data; replaced by the API response once it arrives.
    @Published private(set) var detail: ProductDetail
    @Published var selectedImageIndex = 0

    private let service: ProductDetailsFetching
    private var cancellable: AnyCancellable?

    init(product: Product, service: ProductDetailsFetching = ProductDetailsService()) {
        self.detail = ProductDetail(summary: product)
        self.service = service
    }

    init(detail: ProductDetail, service: ProductDetailsFetching = ProductDetailsService()) {
        self.detail = detail
        self.service = service
    }

    func load() {
        guard state != .loading else { return }
        state = .loading
        cancellable = service.fetchProduct(id: detail.id)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.state = .failed(Self.message(for: error))
                }
            }, receiveValue: { [weak self] product in
                self?.detail = product
                self?.selectedImageIndex = 0
                self?.state = .loaded
            })
    }

    // MARK: - Presentation

    /// Gallery images; falls back to the thumbnail when the product has no image list.
    var imageURLs: [URL] {
        let urls = detail.images.compactMap { URL(string: $0) }
        if !urls.isEmpty { return urls }
        return URL(string: detail.thumbnail).map { [$0] } ?? []
    }

    var hasDiscount: Bool { detail.discountPercentage > 0 }

    var discountedPrice: Double {
        detail.price * (1 - detail.discountPercentage / 100)
    }

    var priceText: String { Self.currency(hasDiscount ? discountedPrice : detail.price) }
    var originalPriceText: String { Self.currency(detail.price) }
    var discountText: String { String(format: "-%.0f%%", detail.discountPercentage) }
    var ratingText: String { String(format: "%.1f", detail.rating) }

    var availabilityText: String {
        if let status = detail.availabilityStatus, !status.isEmpty {
            return "\(status) (\(detail.stock) left)"
        }
        return detail.stock > 0 ? "In Stock (\(detail.stock) left)" : "Out of Stock"
    }

    var dimensionsText: String? {
        guard let d = detail.dimensions else { return nil }
        return String(format: "%.1f × %.1f × %.1f", d.width, d.height, d.depth)
    }

    /// Label/value pairs shown in the "Details" section; missing values are skipped.
    var infoRows: [(label: String, value: String)] {
        var rows: [(String, String?)] = [
            ("Brand", detail.brand),
            ("Category", detail.category.isEmpty ? nil : detail.category.capitalized),
            ("SKU", detail.sku),
            ("Weight", detail.weight.map { String(format: "%.0f", $0) }),
            ("Dimensions", dimensionsText),
            ("Min. order", detail.minimumOrderQuantity.map(String.init)),
            ("Warranty", detail.warrantyInformation),
            ("Shipping", detail.shippingInformation),
            ("Returns", detail.returnPolicy),
            ("Barcode", detail.meta?.barcode)
        ]
        rows.removeAll { ($0.1 ?? "").isEmpty }
        return rows.map { ($0.0, $0.1 ?? "") }
    }

    static func currency(_ value: Double) -> String { String(format: "$%.2f", value) }

    static func message(for error: NetworkError) -> String {
        switch error {
        case .notFound: return "This product could not be found."
        case .urlSessionFailed: return "Check your internet connection and try again."
        case .decodeFailed: return "We couldn't read the product data."
        default: return "Something went wrong loading this product."
        }
    }
}
