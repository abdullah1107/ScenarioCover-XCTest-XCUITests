//
//  LoginUser.swift
//  HandlingGCD
//
//  Created by Muhammad Mamun on 14/10/23.
//

import Foundation


struct LoginUser: Encodable{
    let userName:String
    let password:String
    
    init(userName: String, password: String) {
        self.userName = userName
        self.password = password
    }
    enum CodingKeys: String, CodingKey {
        case userName = "username"
        case password = "password"
    }
}

struct LoginUserResponse: Codable {
    let id:Int
    let username, email, firstName, lastName: String
    let gender: String
    let image: String
    /// Auth token. dummyjson now returns it as `accessToken`; older responses used `token`.
    let token: String
    let refreshToken: String?

    private enum CodingKeys: String, CodingKey {
        case id, username, email, firstName, lastName, gender, image
        case token, accessToken, refreshToken
    }

    init(id: Int, username: String, email: String, firstName: String, lastName: String,
         gender: String, image: String, token: String, refreshToken: String? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.gender = gender
        self.image = image
        self.token = token
        self.refreshToken = refreshToken
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        username = try c.decode(String.self, forKey: .username)
        email = try c.decode(String.self, forKey: .email)
        firstName = try c.decode(String.self, forKey: .firstName)
        lastName = try c.decode(String.self, forKey: .lastName)
        gender = try c.decode(String.self, forKey: .gender)
        image = try c.decode(String.self, forKey: .image)
        if let access = try c.decodeIfPresent(String.self, forKey: .accessToken) {
            token = access
        } else {
            token = try c.decode(String.self, forKey: .token)
        }
        refreshToken = try c.decodeIfPresent(String.self, forKey: .refreshToken)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(username, forKey: .username)
        try c.encode(email, forKey: .email)
        try c.encode(firstName, forKey: .firstName)
        try c.encode(lastName, forKey: .lastName)
        try c.encode(gender, forKey: .gender)
        try c.encode(image, forKey: .image)
        try c.encode(token, forKey: .token)
        try c.encodeIfPresent(refreshToken, forKey: .refreshToken)
    }
}
