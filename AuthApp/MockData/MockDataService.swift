//
//  MockDataService.swift
//  AuthenticationSwiftUI
//
//  Created by Muhammad Mamun on 7/12/23.
//

import Foundation

class MockDataService {
    static let shared = MockDataService()
    
    private init() {}
    
    // MARK: - Load Users
    func loadUsers() -> [LoginUserResponse] {
        // Try loading from MockData subdirectory first, then from main bundle
        var url: URL?
        
        if let subdirectoryURL = Bundle.main.url(forResource: "users", withExtension: "json", subdirectory: "MockData") {
            url = subdirectoryURL
        } else if let mainURL = Bundle.main.url(forResource: "users", withExtension: "json") {
            url = mainURL
        }
        
        guard let fileURL = url,
              let data = try? Data(contentsOf: fileURL) else {
            print("Failed to load users.json from bundle")
            return []
        }
        
        do {
            let users = try JSONDecoder().decode([LoginUserResponse].self, from: data)
            return users
        } catch {
            print("Failed to decode users.json: \(error)")
            return []
        }
    }
    
    // MARK: - Load Products
    func loadProducts() -> HomeDashBoard? {
        // Try loading from MockData subdirectory first, then from main bundle
        var url: URL?
        
        if let subdirectoryURL = Bundle.main.url(forResource: "products", withExtension: "json", subdirectory: "MockData") {
            url = subdirectoryURL
        } else if let mainURL = Bundle.main.url(forResource: "products", withExtension: "json") {
            url = mainURL
        }
        
        guard let fileURL = url,
              let data = try? Data(contentsOf: fileURL) else {
            print("Failed to load products.json from bundle")
            return nil
        }
        
        do {
            let dashboard = try JSONDecoder().decode(HomeDashBoard.self, from: data)
            return dashboard
        } catch {
            print("Failed to decode products.json: \(error)")
            return nil
        }
    }
    
    // MARK: - Authenticate User
    func authenticateUser(username: String, password: String) -> Result<LoginUserResponse, LoginError> {
        let users = loadUsers()
        
        // For mock data, we'll accept any password if username matches
        // In a real app, you'd verify the password properly
        if let user = users.first(where: { $0.username == username }) {
            // Accept any password for mock data (or you can add password field to users.json)
            return .success(user)
        }
        
        return .failure(.networkError)
    }
}

