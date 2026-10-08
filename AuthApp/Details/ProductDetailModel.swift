//
//  ProductDetailModel.swift
//  AuthUI
//  Created by Muhammad Mamun on 9/12/23.

//  Full product payload returned by GET https://dummyjson.com/products/{id}.
//  Only `id`, `title` and `price` are required; everything else falls back to an
//  empty value so partial payloads (and older API versions) still decode.
//

import Foundation

struct ProductDetail: Codable, Identifiable {

    struct Dimensions: Codable {
        let width: Double
        let height: Double
        let depth: Double
    }

    struct Review: Codable, Identifiable {
        let rating: Int
        let comment: String
        let date: String
        let reviewerName: String
        let reviewerEmail: String

        var id: String { "\(reviewerEmail)|\(date)|\(comment)" }
    }

    struct Meta: Codable {
        let createdAt: String?
        let updatedAt: String?
        let barcode: String?
        let qrCode: String?
    }

    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Double
    let discountPercentage: Double
    let rating: Double
    let stock: Int
    let tags: [String]
    let brand: String?
    let sku: String?
    let weight: Double?
    let dimensions: Dimensions?
    let warrantyInformation: String?
    let shippingInformation: String?
    let availabilityStatus: String?
    let reviews: [Review]
    let returnPolicy: String?
    let minimumOrderQuantity: Int?
    let meta: Meta?
    let images: [String]
    let thumbnail: String

    init(id: Int, title: String, description: String = "", category: String = "", price: Double,
         discountPercentage: Double = 0, rating: Double = 0, stock: Int = 0, tags: [String] = [],
         brand: String? = nil, sku: String? = nil, weight: Double? = nil, dimensions: Dimensions? = nil,
         warrantyInformation: String? = nil, shippingInformation: String? = nil,
         availabilityStatus: String? = nil, reviews: [Review] = [], returnPolicy: String? = nil,
         minimumOrderQuantity: Int? = nil, meta: Meta? = nil, images: [String] = [], thumbnail: String = "") {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.price = price
        self.discountPercentage = discountPercentage
        self.rating = rating
        self.stock = stock
        self.tags = tags
        self.brand = brand
        self.sku = sku
        self.weight = weight
        self.dimensions = dimensions
        self.warrantyInformation = warrantyInformation
        self.shippingInformation = shippingInformation
        self.availabilityStatus = availabilityStatus
        self.reviews = reviews
        self.returnPolicy = returnPolicy
        self.minimumOrderQuantity = minimumOrderQuantity
        self.meta = meta
        self.images = images
        self.thumbnail = thumbnail
    }

    /// Builds a placeholder from the list item so the screen has content before the API answers.
    init(summary product: Product) {
        self.init(id: product.id, title: product.title, description: product.description,
                  category: product.category, price: product.price,
                  discountPercentage: product.discountPercentage, rating: product.rating,
                  stock: product.stock, brand: product.brand.isEmpty ? nil : product.brand,
                  images: product.images, thumbnail: product.thumbnail)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, description, category, price, discountPercentage, rating, stock, tags, brand, sku
        case weight, dimensions, warrantyInformation, shippingInformation, availabilityStatus
        case reviews, returnPolicy, minimumOrderQuantity, meta, images, thumbnail
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        price = try c.decode(Double.self, forKey: .price)
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? ""
        discountPercentage = try c.decodeIfPresent(Double.self, forKey: .discountPercentage) ?? 0
        rating = try c.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        stock = try c.decodeIfPresent(Int.self, forKey: .stock) ?? 0
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        brand = try c.decodeIfPresent(String.self, forKey: .brand)
        sku = try c.decodeIfPresent(String.self, forKey: .sku)
        weight = try c.decodeIfPresent(Double.self, forKey: .weight)
        dimensions = try c.decodeIfPresent(Dimensions.self, forKey: .dimensions)
        warrantyInformation = try c.decodeIfPresent(String.self, forKey: .warrantyInformation)
        shippingInformation = try c.decodeIfPresent(String.self, forKey: .shippingInformation)
        availabilityStatus = try c.decodeIfPresent(String.self, forKey: .availabilityStatus)
        reviews = try c.decodeIfPresent([Review].self, forKey: .reviews) ?? []
        returnPolicy = try c.decodeIfPresent(String.self, forKey: .returnPolicy)
        minimumOrderQuantity = try c.decodeIfPresent(Int.self, forKey: .minimumOrderQuantity)
        meta = try c.decodeIfPresent(Meta.self, forKey: .meta)
        images = try c.decodeIfPresent([String].self, forKey: .images) ?? []
        thumbnail = try c.decodeIfPresent(String.self, forKey: .thumbnail) ?? ""
    }
}
