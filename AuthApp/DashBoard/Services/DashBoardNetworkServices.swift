//
//  DashBoardNetworkServices.swift
//  AuthenticationSwiftUI
//
//  Created by Muhammad Mamun on 9/12/23.
//

import Foundation
import Combine


protocol ProductNetworkRequest{
    func getAllProducts<ResponseType: Decodable>(endpoint: String, limit:Int?, skip: Int?, select: String?, responseType: ResponseType.Type) -> Future<ResponseType, NetworkError>
}

extension ProductNetworkRequest {
    /// Convenience for callers that don't need field selection.
    func getAllProducts<ResponseType: Decodable>(endpoint: String, limit:Int?, skip: Int?, responseType: ResponseType.Type) -> Future<ResponseType, NetworkError> {
        getAllProducts(endpoint: endpoint, limit: limit, skip: skip, select: nil, responseType: responseType)
    }
}


class DashBoardProductNetworkServices: ProductNetworkRequest{
    
    private var cancellables = Set<AnyCancellable>()
    let urlSession: URLSession
    
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    /// Builds `<endpoint>?limit=<n>&skip=<n>[&select=<fields>]`.
    static func makeURL(endpoint: String, limit: Int?, skip: Int?, select: String?) -> URL? {
        guard var components = URLComponents(string: endpoint) else { return nil }
        var items = [
            URLQueryItem(name: "limit", value: "\(limit ?? 30)"),
            URLQueryItem(name: "skip", value: "\(skip ?? 0)")
        ]
        if let select = select, !select.isEmpty {
            items.append(URLQueryItem(name: "select", value: select))
        }
        components.queryItems = items
        return components.url
    }
    
    func getAllProducts<ResponseType: Decodable>(endpoint: String, limit:Int?=30, skip: Int? = nil, select: String? = nil, responseType: ResponseType.Type) -> Future<ResponseType, NetworkError>{
        
        return Future <ResponseType, NetworkError> { [weak self] promise in
            
            guard let self = self, let url = DashBoardProductNetworkServices.makeURL(endpoint: endpoint, limit: limit, skip: skip, select: select) else {
                promise(.failure(NetworkError.invalidURL))
                return
            }
            urlSession.dataTaskPublisher(for: url)
                .subscribe(on: DispatchQueue.global(qos: .default))
                .tryMap { (data, response) -> Data in
                    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        throw NetworkError.requestFailed
                    }
                    return data
                }
                .decode(type: ResponseType.self, decoder: JSONDecoder())
                .receive(on: RunLoop.main)
                .sink { (complition) in
                    if case let .failure(error) = complition {
                        switch error {
                        case _ as DecodingError:
                            promise(.failure(NetworkError.decodeFailed))
                        case let apiError as NetworkError:
                            promise(.failure(apiError))
                        default:
                            promise(.failure(NetworkError.unknownError))
                        }
                    }
                }receiveValue: {
                    promise(.success($0))
                }
                .store(in: &self.cancellables)
        }
    }
}












// MARK: - 

//class NetworkManager {
//    
//    private var cancellables = Set<AnyCancellable>()
//    let urlSession: URLSession
//    
//    public init(urlSession: URLSession = .shared) {
//        self.urlSession = urlSession
//    }
//    
//    func performRequest<ResponseType: Decodable>(
//        endpoint: String,
//        method: String = "GET",
//        parameters: [String: Any]? = nil,
//        responseType: ResponseType.Type) -> Future<ResponseType, NetworkError> {
//            
//            return Future<ResponseType, NetworkError> { [weak self] promise in
//                
//                guard let self = self, let url = self.createURL(endpoint: endpoint, parameters: parameters) else {
//                    promise(.failure(NetworkError.invalidURL))
//                    return
//                }
//                var request = URLRequest(url: url)
//                request.httpMethod = method
//                urlSession.dataTaskPublisher(for: request)
//                    .subscribe(on: DispatchQueue.global(qos: .default))
//                    .tryMap({ (data, response) -> Data in
//                        guard let response = response as? HTTPURLResponse else {
//                            throw self.httpError(0)
//                        }
//                        //print("[\(response.statusCode)] '\(request.url!)'")
//                        if !(200...299).contains(response.statusCode) {
//                            throw self.httpError(response.statusCode)
//                        }
//                        return data
//                    })
//                    .decode(type: ResponseType.self, decoder: JSONDecoder())
//                    .receive(on: RunLoop.main)
//                    .sink { completion in
//                        if case let .failure(error) = completion {
//                            switch error {
//                            case _ as DecodingError:
//                                promise(.failure(NetworkError.decodeFailed))
//                            case let apiError as NetworkError:
//                                promise(.failure(apiError))
//                            default:
//                                promise(.failure(NetworkError.unknownError))
//                            }
//                        }
//                    } receiveValue: {
//                        promise(.success($0))
//                    }
//                    .store(in: &self.cancellables)
//            }
//        }
//    
//    private func createURL(endpoint: String, parameters: [String: Any]?) -> URL? {
//        guard var components = URLComponents(string: endpoint) else { return nil }
//        
//        if let parameters = parameters {
//            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
//        }
//        return components.url
//    }
//    
//    
//    /// Parses a HTTP StatusCode and returns a proper error
//    /// - Parameter statusCode: HTTP status code
//    /// - Returns: Mapped Error
//    public func httpError(_ statusCode: Int) -> NetworkError {
//        switch statusCode {
//        case 400: return .badRequest
//        case 401: return .unauthorized
//        case 403: return .forbidden
//        case 404: return .notFound
//        case 402, 405...499: return .error4xx(statusCode)
//        case 500: return .serverError
//        case 501...599: return .error5xx(statusCode)
//        default: return .unknownError
//        }
//    }
// 
//}
