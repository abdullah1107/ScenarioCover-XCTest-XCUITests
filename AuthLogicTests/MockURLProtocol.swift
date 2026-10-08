//
//  MockURLProtocol.swift
//  AuthUITests
//
//  Test support: stubs URLSession responses and awaits Combine publishers.
//

import XCTest
import Combine

final class MockURLProtocol: URLProtocol {

    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)
    static var handler: Handler?

    /// An ephemeral session whose traffic is served by `MockURLProtocol.handler`.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func http(_ url: URL?, status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url ?? URL(string: "https://dummyjson.com")!,
                        statusCode: status,
                        httpVersion: "HTTP/1.1",
                        headerFields: ["Content-Type": "application/json"])!
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

extension URLRequest {
    /// URLProtocol receives bodies as a stream, not `httpBody`.
    func readBody() -> Data? {
        if let httpBody = httpBody { return httpBody }
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

extension XCTestCase {
    /// Waits for the first value (or failure) of a publisher.
    func awaitResult<P: Publisher>(_ publisher: P,
                                   timeout: TimeInterval = 15,
                                   file: StaticString = #filePath,
                                   line: UInt = #line) -> Result<P.Output, P.Failure>? {
        var result: Result<P.Output, P.Failure>?
        let done = expectation(description: "publisher result")
        let cancellable = publisher.first().sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    result = .failure(error)
                    done.fulfill()
                }
            },
            receiveValue: { value in
                result = .success(value)
                done.fulfill()
            })
        if XCTWaiter.wait(for: [done], timeout: timeout) != .completed {
            XCTFail("Timed out waiting for publisher", file: file, line: line)
        }
        cancellable.cancel()
        return result
    }
}
