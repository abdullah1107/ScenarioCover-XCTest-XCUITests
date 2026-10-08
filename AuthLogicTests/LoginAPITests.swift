//
//  LoginAPITests.swift
//  AuthUITests
//
//  Covers POST https://dummyjson.com/auth/login
//   - LoginAPIStubbedTests: deterministic, no network (URLProtocol stub)
//   - LoginAPILiveTests:    hits the real dummyjson.com endpoint
//

import XCTest
import Combine
@testable import AuthUI

// MARK: - Stubbed (offline)

final class LoginAPIStubbedTests: XCTestCase {

    private var service: LoginNetworkService!

    override func setUp() {
        super.setUp()
        service = LoginNetworkService(urlSession: MockURLProtocol.makeSession())
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
        service = nil
        super.tearDown()
    }

    private let accessTokenJSON = """
    {"id":1,"username":"emilys","email":"emily.johnson@x.dummyjson.com","firstName":"Emily",
     "lastName":"Johnson","gender":"female","image":"https://dummyjson.com/icon/emilys/128",
     "accessToken":"access-123","refreshToken":"refresh-456"}
    """

    private let legacyTokenJSON = """
    {"id":15,"username":"kminchelle","email":"kminchelle@qq.com","firstName":"Jeanne",
     "lastName":"Halvorson","gender":"female","image":"https://robohash.org/Jeanne.png","token":"legacy-789"}
    """

    func testLoginURLIsDummyJSONAuthLogin() {
        XCTAssertEqual(LoginAPI.getLoginRequestUrl.absoluteString, "https://dummyjson.com/auth/login")
    }

    func testLoginRequestIsJSONPostWithCredentials() throws {
        var captured: URLRequest?
        MockURLProtocol.handler = { request in
            captured = request
            return (MockURLProtocol.http(request.url, status: 200), Data(self.accessTokenJSON.utf8))
        }

        let result = awaitResult(service.createUser(urlPath: LoginAPI.getLoginRequestUrl,
                                                    user: LoginUser(userName: "emilys", password: "emilyspass"),
                                                    responseType: LoginUserResponse.self))
        XCTAssertNotNil(try result?.get())

        let request = try XCTUnwrap(captured)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://dummyjson.com/auth/login")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(request.readBody())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
        XCTAssertEqual(json["username"], "emilys")
        XCTAssertEqual(json["password"], "emilyspass")
    }

    func testLoginDecodesAccessTokenResponse() throws {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.http(request.url, status: 200), Data(self.accessTokenJSON.utf8))
        }
        let user = try XCTUnwrap(awaitResult(service.createUser(urlPath: LoginAPI.getLoginRequestUrl,
                                                                user: LoginUser(userName: "emilys", password: "emilyspass"),
                                                                responseType: LoginUserResponse.self))?.get())
        XCTAssertEqual(user.id, 1)
        XCTAssertEqual(user.username, "emilys")
        XCTAssertEqual(user.token, "access-123")
        XCTAssertEqual(user.refreshToken, "refresh-456")
    }

    func testLoginResponseStillDecodesLegacyTokenField() throws {
        let user = try JSONDecoder().decode(LoginUserResponse.self, from: Data(legacyTokenJSON.utf8))
        XCTAssertEqual(user.token, "legacy-789")
        XCTAssertNil(user.refreshToken)
    }

    func testInvalidCredentialsReturn400AndFail() throws {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.http(request.url, status: 400), Data(#"{"message":"Invalid credentials"}"#.utf8))
        }
        let result = awaitResult(service.createUser(urlPath: LoginAPI.getLoginRequestUrl,
                                                    user: LoginUser(userName: "nobody", password: "wrongpass"),
                                                    responseType: LoginUserResponse.self))
        guard case .failure(let error)? = result else { return XCTFail("Expected failure, got \(String(describing: result))") }
        XCTAssertEqual(error as? NetworkError, .invalidResponse)
    }

    func testMalformedBodyFailsToDecode() {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.http(request.url, status: 200), Data(#"{"unexpected":true}"#.utf8))
        }
        let result = awaitResult(service.createUser(urlPath: LoginAPI.getLoginRequestUrl,
                                                    user: LoginUser(userName: "emilys", password: "emilyspass"),
                                                    responseType: LoginUserResponse.self))
        guard case .failure? = result else { return XCTFail("Expected decoding failure") }
    }

    // MARK: View model on top of the stubbed service

    private func login(_ viewModel: LoginViewModel, _ username: String?, _ password: String?) -> Result<Bool, Error>? {
        var outcome: Result<Bool, Error>?
        let done = expectation(description: "login completion")
        viewModel.creareNewUserStatus(username: username, password: password) { result in
            outcome = result
            done.fulfill()
        }
        wait(for: [done], timeout: 10)
        return outcome
    }

    func testViewModelLoginSucceedsOn200() throws {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.http(request.url, status: 200), Data(self.accessTokenJSON.utf8))
        }
        let viewModel = LoginViewModel(loginService: service)
        let result = try XCTUnwrap(login(viewModel, "emilys", "emilyspass"))
        XCTAssertTrue(try result.get())
        XCTAssertTrue(viewModel.success)
    }

    func testViewModelLoginFailsOn400() throws {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.http(request.url, status: 400), Data(#"{"message":"Invalid credentials"}"#.utf8))
        }
        let viewModel = LoginViewModel(loginService: service)
        guard case .failure(let error)? = login(viewModel, "nobody1", "wrongpass") else { return XCTFail("Expected failure") }
        XCTAssertEqual(error as? LoginError, .networkError)
        XCTAssertFalse(viewModel.success)
    }

    func testViewModelRejectsEmptyInputWithoutCallingAPI() {
        var apiCalled = false
        MockURLProtocol.handler = { request in
            apiCalled = true
            return (MockURLProtocol.http(request.url, status: 200), Data(self.accessTokenJSON.utf8))
        }
        let viewModel = LoginViewModel(loginService: service)
        for (u, p) in [("", "x"), ("x", ""), (nil, "x"), ("x", nil)] as [(String?, String?)] {
            guard case .failure(let error)? = login(viewModel, u, p) else { return XCTFail("Expected failure") }
            XCTAssertEqual(error as? LoginError, .invalidInput)
        }
        XCTAssertFalse(apiCalled)
    }
}

// MARK: - Live (real network)

/// Calls the real https://dummyjson.com/auth/login. Needs internet access.
final class LoginAPILiveTests: XCTestCase {

    func testLiveLoginWithValidCredentialsSucceeds() throws {
        let result = awaitResult(LoginNetworkService().createUser(urlPath: LoginAPI.getLoginRequestUrl,
                                                                  user: LoginUser(userName: "emilys", password: "emilyspass"),
                                                                  responseType: LoginUserResponse.self),
                                 timeout: 20)
        let user = try XCTUnwrap(result?.get(), "Login request failed")
        XCTAssertEqual(user.username, "emilys")
        XCTAssertFalse(user.token.isEmpty, "Expected a non-empty token")
    }

    func testLiveLoginWithInvalidCredentialsFails() throws {
        let result = awaitResult(LoginNetworkService().createUser(urlPath: LoginAPI.getLoginRequestUrl,
                                                                  user: LoginUser(userName: "not-a-user", password: "wrong-password"),
                                                                  responseType: LoginUserResponse.self),
                                 timeout: 20)
        guard case .failure(let error)? = result else { return XCTFail("Expected failure for bad credentials") }
        XCTAssertEqual(error as? NetworkError, .invalidResponse)
    }

    func testLiveViewModelLoginSucceeds() throws {
        let done = expectation(description: "login")
        var outcome: Result<Bool, Error>?
        let viewModel = LoginViewModel()
        viewModel.creareNewUserStatus(username: "emilys", password: "emilyspass") { result in
            outcome = result
            done.fulfill()
        }
        wait(for: [done], timeout: 20)
        XCTAssertTrue(try XCTUnwrap(outcome).get())
    }
}
