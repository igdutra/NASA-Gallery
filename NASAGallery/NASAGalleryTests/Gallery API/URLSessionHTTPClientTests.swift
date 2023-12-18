//
//  URLSessionHTTPClientTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 16/12/23.
//

import XCTest

/* NOTE Author Notes
 
 1- The first TDD approach was through subclassing URLSession.
 However that was not possible because "Non @objc instance method 'data(from:)' is declared in extension of 'URLSession' and cannot be overridden"

 2- So the second approach was done throuh Protocol-Based Mocking. Which works! but the downside is that only because of the tests we had to add complexity and new protocols to the production code
 
 */

/* TODOs
 
*/
final class URLSessionHTTPClient {
    // Note how must be the protocol in production code and not the real URLSession
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func getData(from url: URL) async throws {
        _ = try await session.data(from: url)
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
//    func test_getData_firesSessionDataFromURL() async {
//        let url = anyURL()
//        let sessionSpy = URLSessionSpy()
//        sessionSpy.stub(url: url, error: AnyError())
//        let sut = URLSessionHTTPClient(session: sessionSpy)
//        
//        try? await sut.getData(from: url)
//        
//        XCTAssertEqual(sessionSpy.receivedMessages, [.data(url)])
//    }
    
//    func test_getFromURL_failsOnRequestError() async {
//        let url = anyURL()
//        let expectedError = AnyError(message: "Expected Error")
//        let sessionSpy = URLSessionSpy()
//        sessionSpy.stub(url: url, error: expectedError)
//        let sut = URLSessionHTTPClient(session: sessionSpy)
//
//        do {
//            try await sut.getData(from: url)
//            XCTFail("Expected Error but returned successfully instead")
//        } catch {
//            XCTAssertEqual(error as? AnyError, expectedError)
//        }
//    }
    
    func test_getFromURL_failsOnRequestError2() async {
        let url = anyURL()
        // Return from URLprotocol stub is AnyError wrapped into NSError. casting error as? AnyError Fails.
        let expectedError = NSError(domain: "any error", code: 13)
        URLProtocolStub.startInterceptingRequests()
        
        URLProtocolStub.stub(url: url, data: nil, response: nil, error: expectedError)
        let sut = URLSessionHTTPClient(session: .shared)

        do {
            try await sut.getData(from: url)
            XCTFail("Expected Error but returned successfully instead")
        } catch let nsError as NSError {
            XCTAssertEqual(nsError.domain, expectedError.domain)
        }
        
        URLProtocolStub.stopInterceptingRequests()
    }
}

// MARK: - URLProtocolStub

private extension URLSessionHTTPClientTests {
    private class URLProtocolStub: URLProtocol {
        // MARK: Properties and Helpers
        
        private static var stubs: [URL: Stub] = .init()
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(url: URL, data: Data?, response: URLResponse?, error: Error?) {
            stubs[url] = Stub(data: data, response: response, error: error)
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stubs = [:]
        }
        
        // MARK: - URLProtocol
        override class func canInit(with: URLRequest) -> Bool { true }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else { XCTFail("Should mock"); return }
            
            
            
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() { }
    }
}

// MARK: - Alternative Approach: Protocol-based mocking

protocol URLSessionProtocol {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol { }

private final class URLSessionSpy: URLSessionProtocol {
    // MARK: Messages
    enum ReceivedMessage: Equatable {
        case data(URL)
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    // MARK: Stubs
    struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }
    private var stubs: [URL: Stub] = [:]
    
    func stub(url: URL, data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
        stubs[url] = Stub(data: data, response: response, error: error)
    }
        
    // MARK: - URLSessionProtocol
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        receivedMessages.append(.data(url))
        
        guard let stub = stubs[url] else { throw AnyError(message: "Missing stub for \(url)") }
        
        if let error = stub.error {
            throw error
        }
        
        guard let data = stub.data,
              let response = stub.response else {
            throw AnyError(message: "Stub for \(url) must provide both data and response when there is no error.")
        }
        
        return (data, response)
    }
}
