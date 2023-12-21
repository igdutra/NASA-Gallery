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
This was done more like an exercise, we could make the point that made the codebase more complicated.
 
5- Added new testcase to assure that this client will only take HTTP responses
*/

/* TODOs
 
*/
final class URLSessionHTTPClient {
    
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func getData(from url: URL) async throws -> (data: Data, response: HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.cannotParseResponse)
            }
            
            return (data: data, response: httpResponse)
        } catch {
            throw error
        }
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
        
        let sut = makeSUT()
        
        let _ = try? await sut.getData(from: url)
        
        XCTAssertNotNil(observedRequest)
        XCTAssertEqual(observedRequest?.url, url)
    }
    
    // MARK: Error Cases
    
    func test_getFromURL_failsOnRequestError() async {
        // Needs to be NSError
        let expectedError = NSError(domain: "failsOnRequestError", code: 13)
        let url = anyURL()
     
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)
        let sut = makeSUT()
        
        await assertFailsWithNSError(expectedError) {
            _ = try await sut.getData(from: url)
        }
    }
    
    func test_getFromURL_failsOnNonHTTPURLResponse() async {
        let validReturn = Data()
        let url = anyURL()
        let nonHTTPResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
     
        URLProtocolStub.stub(data: validReturn, response: nonHTTPResponse, error: nil)
        let sut = makeSUT()
        
        do {
            _ = try await sut.getData(from: url)
            XCTFail("Expected Error but returned successfully instead")
        } catch let error as URLError {
            XCTAssertEqual(error, URLError(.cannotParseResponse))
        } catch {
            XCTFail("Should throw expectedError but threw \(error) instead")
        }
    }
    
    // MARK: Success Cases
    
    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() async throws {
        let expectedReturn = Data()
        let url = anyURL()
        let validResponse = HTTPURLResponse(url: url,
                                            statusCode: 200, httpVersion: nil, headerFields: nil)
     
        URLProtocolStub.stub(data: expectedReturn, response: validResponse, error: nil)
        let sut = makeSUT()
        
        let receivedReturn = try await sut.getData(from: url)
        
        XCTAssertEqual(receivedReturn.data, expectedReturn)
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() async throws {
        let expectedReturn = makeItems().data
        let url = anyURL()
        let validResponse = HTTPURLResponse(url: url,
                                            statusCode: 200, httpVersion: nil, headerFields: nil)
     
        URLProtocolStub.stub(data: expectedReturn, response: validResponse, error: nil)
        let sut = makeSUT()
        
        let receivedReturn = try await sut.getData(from: url)
        
        XCTAssertEqual(receivedReturn.data, expectedReturn)
    }
    
    // MARK: Documentation
    
    // Test as documentation: assert that Stub will not behave differenlty as it should
    func test_getFromURL_failsOnAllInvalidRepresentationCases() async {
        let anyData = Data()
        let anyResponse = URLResponse()
        let anyError = anyErrorErased("Any Error")
        
        let expectedError: NSError = URLProtocolStub.invalidRepresentationError
        
        let invalidStubs: [(Data?, URLResponse?, Error?)] = [
            (nil, nil, nil),
            (anyData, anyResponse, anyError),
            (anyData, nil, nil),
            (nil, anyResponse, nil),
            (nil, anyResponse, anyError),
            (anyData, nil, anyError)
        ]
        
        let sut = makeSUT()
        
        for (data, response, error) in invalidStubs {
            URLProtocolStub.stub(data: data, response: response, error: error)
            let scenarioDescription = "data: \(data != nil), response: \(response != nil), error: \(error != nil)"
            do {
                _ = try await sut.getData(from: anyURL())
                XCTFail("Expected failure, but got success for scenario: \(data != nil), \(response != nil), \(error != nil)")
            } catch let receivedError as NSError {
                XCTAssertEqual(receivedError.code, expectedError.code, "Failed for scenario: \(scenarioDescription)")
                XCTAssertEqual(receivedError.domain, expectedError.domain, "Failed for scenario: \(scenarioDescription)")
            }
        }
    }
}

// MARK: - Helpers
private extension URLSessionHTTPClientTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        
        trackForMemoryLeaks(sut)
        
        return sut
    }
    
    func assertFailsWithNSError(_ expectedNSError: NSError,
                                action: () async throws -> Void, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            try await action()
            XCTFail("Expected Error but returned successfully instead", file: file, line: line)
        } catch let error as NSError {
            XCTAssertEqual(error.code, expectedNSError.code, file: file, line: line)
            XCTAssertEqual(error.domain, expectedNSError.domain, file: file, line: line)
        } catch {
            XCTFail("Should throw expectedError but threw \(error) instead")
        }
    }
    
    func assertFailsWith<ErrorType: Error>(_ expectedError: ErrorType,
                                           action: () async throws -> Void,
                                           file: StaticString = #filePath, line: UInt = #line) async where ErrorType: Equatable {
        do {
            try await action()
            XCTFail("Expected Error but returned successfully instead", file: file, line: line)
        } catch let error as ErrorType {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Should throw expectedError but threw \(error) instead")
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
            case (nil, nil, nil),
                 (.some(_), .some(_), .some(_)),
                 (.some(_), nil, nil),
                 (nil, .some(_), nil),
                 (nil, .some(_), .some(_)),
                 (.some(_), nil, .some(_)):
                return false
            default:
                return true
            }
        }
    }
}

// MARK: - Alternative Approach: Protocol-based mocking (not applied)

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
