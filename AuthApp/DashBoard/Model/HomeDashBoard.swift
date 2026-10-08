//
//  HomeDashBoard.swift
//  AuthenticationSwiftUI
//
//  Created by Muhammad Mamun on 9/12/23.
//

import Foundation

// MARK: - BaseModel
struct HomeDashBoard: Codable {
    let products: [Product]
    let total, skip, limit: Int
}

// MARK: - Product
/// Only `id`, `title` and `price` are guaranteed (the products endpoint can be called with
/// `select=title,price`); every other field falls back to an empty/zero value when absent.
struct Product: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let discountPercentage, rating: Double
    let stock: Int
    let brand, category: String
    let thumbnail: String
    let images: [String]

    init(id: Int, title: String, description: String = "", price: Double,
         discountPercentage: Double = 0, rating: Double = 0, stock: Int = 0,
         brand: String = "", category: String = "", thumbnail: String = "", images: [String] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.discountPercentage = discountPercentage
        self.rating = rating
        self.stock = stock
        self.brand = brand
        self.category = category
        self.thumbnail = thumbnail
        self.images = images
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, description, price, discountPercentage, rating, stock
        case brand, category, thumbnail, images
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        price = try c.decode(Double.self, forKey: .price)
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        discountPercentage = try c.decodeIfPresent(Double.self, forKey: .discountPercentage) ?? 0
        rating = try c.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        stock = try c.decodeIfPresent(Int.self, forKey: .stock) ?? 0
        brand = try c.decodeIfPresent(String.self, forKey: .brand) ?? ""
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? ""
        thumbnail = try c.decodeIfPresent(String.self, forKey: .thumbnail) ?? ""
        images = try c.decodeIfPresent([String].self, forKey: .images) ?? []
    }
}
