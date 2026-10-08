//
//  HomeViewModel.swift
//  AuthenticationSwiftUI
//
//  Created by Muhammad Mamun on 9/12/23.
//

import Foundation
import Combine
import SwiftUI

class DashBoadProductViewModel: ObservableObject{
    
    private var cancellables = Set<AnyCancellable>()
    @Published var products:[Product] = []
    @Published var isFetching: Bool = false
    private var currentPage: Int = 0
    private let productNetworkService: ProductNetworkRequest?
    
    init(productNetworkService:ProductNetworkRequest? = DashBoardProductNetworkServices()){
        self.productNetworkService = productNetworkService
    }
    
    func getAllProducts(){
        guard !isFetching else { return }
        isFetching = true
        
        productNetworkService?.getAllProducts(endpoint:"https://dummyjson.com/products", limit: 10, skip: currentPage * 10, responseType: HomeDashBoard.self)
            .sink { completion in
                switch completion {
                case .failure(let err):
                    print("Error is \(err.localizedDescription)")
                case .finished:
                    print("Finished")
                    break
                }
            }
    receiveValue: { [weak self] totalProducts in
        self?.products.append(contentsOf: totalProducts.products)
        self?.currentPage += 1
        self?.isFetching = false
    }
     .store(in: &cancellables)
    }
    
}


final class ImageLoader: ObservableObject {
    @Published var downloadedImage: UIImage?
    private var cancellable: AnyCancellable?
    
    func loadImage(from url: URL) {
        if let cachedImage = ImageCache.shared.image(forKey: url.absoluteString) {
            downloadedImage = cachedImage
            return
        }
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .compactMap { UIImage(data: $0) }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Image loading error: \(error)")
                }
            }, receiveValue: { image in
                self.downloadedImage = image
                ImageCache.shared.saveImage(image, forKey: url.absoluteString)
            })
    }

}

final class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()

    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: NSString(string: key))
    }

    func saveImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: NSString(string: key))
    }
}



// Use mock data service for products
//        if let dashboard = MockDataService.shared.loadProducts() {
//            DispatchQueue.main.async { [weak self] in
//                self?.products.append(contentsOf: dashboard.products)
//                self?.currentPage += 1
//                self?.isFetching = false
//            }
//        } else {
//            DispatchQueue.main.async { [weak self] in
//                self?.isFetching = false
//                print("Failed to load products from mock data")
//            }
//        }

// Original API call (commented out - uncomment to use API instead of mock data)
