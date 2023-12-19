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
 
3- Return from URLProtocol stub is the expected error (client?.urlProtocol(self, didFailWithError: error), however wrapped into NSError.
   If expectedError is AnyError, casting returned error as? AnyError Fails.
 
4- test_getFromURL_failsOnAllInvalidRepresentationCases
Since this is using async/await, in production code, we will never have a Invalid Case!
So this test was added only for documentation purposes, to assert that the stub handles that correctly!
 
*/

/* TODOs
 
*/
final class URLSessionHTTPClient {
    
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func getData(from url: URL) async throws {
        _ = try await session.data(from: url)
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    // MARK: - SetUp & TearDown
    
    override func setUp() async throws {
        try await super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() async throws {
        URLProtocolStub.stopInterceptingRequests()
        try await super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_getFromURL_performsGETRequestWithURL() async {
        let url = anyURL()
        URLProtocolStub.stub(data: nil, response: nil, error: AnyError())
        
        var observedRequest: URLRequest?
        
        URLProtocolStub.captureRequest { request in
            observedRequest = request
        }
        
        let sut = URLSessionHTTPClient()
        
        let _ = try? await sut.getData(from: url)
        
        XCTAssertNotNil(observedRequest)
        XCTAssertEqual(observedRequest?.url, url)
    }
    
    func test_getFromURL_failsOnRequestError() async {
        // Needs to be NSError
        let expectedError: NSError = anyErrorErased() as NSError
        let url = anyURL()
     
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)
        let sut = URLSessionHTTPClient()

        do {
            try await sut.getData(from: url)
            XCTFail("Expected Error but returned successfully instead")
        } catch let nsError as NSError {
            XCTAssertEqual(nsError.code, expectedError.code)
            XCTAssertEqual(nsError.domain, expectedError.domain)
        } catch {
            // Should never run due to URLProtocolStub returning NSError
            XCTFail("Should throw expectedError but threw \(error) instead")
        }
    }
    
    // Test as documentation: assert that Stub will not behave differenlty as it should
    func test_getFromURL_failsOnAllInvalidRepresentationCases() async {
        let anyData = Data()
        let anyResponse = URLResponse()
        let anyError = anyErrorErased("Any Error")
        
        let expectedError: NSError = URLProtocolStub.invalidRepresentationError
        
        URLProtocolStub.stub(data: nil, response: nil, error: nil)
//        URLProtocolStub.stub(data: anyData, response: anyResponse, error: anyError)
//        URLProtocolStub.stub(data: anyData, response: nil, error: nil)
//        URLProtocolStub.stub(data: nil, response: anyResponse, error: nil)
//        URLProtocolStub.stub(data: nil, response: anyResponse, error: anyError)
//        URLProtocolStub.stub(data: anyData, response: nil, error: anyError)
        
        let sut = URLSessionHTTPClient()
        
        do {
            try await sut.getData(from: anyURL())
        } catch let receivedError as NSError {
            XCTAssertEqual(receivedError.code, expectedError.code)
            XCTAssertEqual(receivedError.domain, expectedError.domain)
        }
    }
}

// MARK: - URLProtocolStub

private extension URLSessionHTTPClientTests {
    private class URLProtocolStub: URLProtocol {
        // MARK: Properties and Helpers
        
        private static var stub: Stub?
        
        private static var captureRequest: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func captureRequest(observer: @escaping (URLRequest) -> Void) {
            captureRequest = observer
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            captureRequest = nil
        }
        
        // MARK: - URLProtocol
        
        override class func canInit(with request: URLRequest) -> Bool {
            captureRequest?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let stub = URLProtocolStub.stub else {
                // XCTFail() was not being displayed correctly, better crash instead.
                // Missing client didfinishloading
                fatalError("Test needs a stubbed response")
            }
            
            guard URLProtocolStub.isValidStub() else {
                client?.urlProtocol(self, didFailWithError: URLProtocolStub.invalidRepresentationError)
                client?.urlProtocolDidFinishLoading(self)
                return
            }
            
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
        
        // MARK: - Helpers
        
        static let invalidRepresentationError = NSError(domain: "Invalid Representation Error", code: 1)
        
        static func isValidStub() -> Bool {
            // Represent the invalid cases here
            switch (stub?.data, stub?.response, stub?.error) {
            case (nil, nil, nil):
                return false
            case (.some(_), _, _):
                return true
            case (_, .some(_), _):
                return true
            case (_, _, .some(_)):
                return true
            }
        }
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
