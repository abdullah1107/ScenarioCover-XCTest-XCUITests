//
//  LoginService.swift
//  AuthenticationSwiftUI
//
//  Created by Muhammad Mamun on 20/11/23.
//

import Foundation
import Combine

final class LoginNetworkService{

    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

     func createUser<T:Decodable>(urlPath: URL, user: LoginUser, responseType: T.Type) -> AnyPublisher<T, Error>{
        
        var request = URLRequest(url: urlPath)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do{
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(user)
            request.httpBody = jsonData
        }catch{
            return Fail(error: NetworkError.encodeFailed).eraseToAnyPublisher()
        }
        
        return urlSession.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.invalidResponse
                }
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
        
        
        
// MARK: - @escaping

//    func createUser(user: LoginUser, completion: @escaping(Result<LoginUserResponse, Error>) -> Void){
//        
//        guard let url = URL(string: "https://dummyjson.com/auth/login") else {
//            completion(.failure(NetworkError.invalidURL))
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        do{
//            let jsonEncoder = JSONEncoder()
//            let jsonData = try jsonEncoder.encode(user)
//            request.httpBody = jsonData
//        }catch{
//            completion(.failure(error))
//            return
//        }
//        
//        URLSession.shared.dataTask(with: request){ data, response, error in
//            
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let data = data else {
//                completion(.failure(NetworkError.invalidResponse))
//                return
//            }
//            
//            do {
//                let createdUser = try JSONDecoder().decode(LoginUserResponse.self, from: data)
//                completion(.success(createdUser))
//            } catch {
//                completion(.failure(NetworkError.invalidResponse))
//            }
//        }.resume()
//    }
//
//}
