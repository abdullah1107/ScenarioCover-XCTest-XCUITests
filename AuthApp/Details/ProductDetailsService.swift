//
//  ProductDetailsService.swift
//  AuthUI
//
//  GET https://dummyjson.com/products/{id}
//

import Foundation
import Combine

protocol ProductDetailsFetching {
    func fetchProduct(id: Int) -> AnyPublisher<ProductDetail, NetworkError>
}

final class ProductDetailsService: ProductDetailsFetching {

    private let urlSession: URLSession
    private let baseURL: String

    init(urlSession: URLSession = .shared, baseURL: String = APIConstants.basedURL) {
        self.urlSession = urlSession
        self.baseURL = baseURL
    }

    static func makeURL(baseURL: String, id: Int) -> URL? {
        URL(string: "\(baseURL)/products/\(id)")
    }

    func fetchProduct(id: Int) -> AnyPublisher<ProductDetail, NetworkError> {
        guard let url = Self.makeURL(baseURL: baseURL, id: id) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.acceptType.rawValue)

        return urlSession.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
                switch http.statusCode {
                case 200...299: return data
                case 404: throw NetworkError.notFound
                default: throw NetworkError.requestFailed
                }
            }
            .decode(type: ProductDetail.self, decoder: JSONDecoder())
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError { return networkError }
                if error is DecodingError { return .decodeFailed }
                if let urlError = error as? URLError { return .urlSessionFailed(urlError) }
                return .unknownError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
