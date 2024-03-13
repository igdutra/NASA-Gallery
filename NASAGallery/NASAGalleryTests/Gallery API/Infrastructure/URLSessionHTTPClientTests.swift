//
//  URLSessionHTTPClientTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 16/12/23.
//

import XCTest
import NASAGallery

/* Author Notes on URLSessionHTTPClientTests
 
 * Possible DataRace on test_getFromURL_performsGETRequestWithURL
 In the program, a data race was detected in this test because the result was not needed for this test to work.
 Note that because we are using async/await, the data race WILL NOT occour on this test because right from the start we await for the return in order to make our assertions!
 
 1- The first TDD approach was through subclassing URLSession.
 However that was not possible because "Non @objc instance method 'data(from:)' is declared in extension of 'URLSession' and cannot be overridden"

 2- So the second approach was done throuh Protocol-Based Mocking. Which works! but the downside is that only because of the tests we had to add complexity and new protocols to the production code
 
3- Return from URLProtocol stub is the expected error (client?.urlProtocol(self, didFailWithError: error), however wrapped into NSError.
   If expectedError is AnyError, casting returned error as? AnyError Fails.
 
4- test_getFromURL_failsOnAllInvalidRepresentationCases
Since this is using async/await, in production code, we will never have a Invalid Case!
So this test was added only for documentation purposes, to assert that the stub handles that correctly!
This was done more like an exercise, we could make the point that made the codebase more complicated.
 
5- Added new testcase to assure that this client will only take HTTP responses, it returns HTTPClientResult which expects HTTPURLResponse.
This was represented in the invalid scenarios testcase from them
 (.. } else if let data = data, let response = response as? HTTPURLResponse { )
 but in here we used guard syntax
 
6- Note how EASILY the production URLSessionHTTPClient could be replaced by a simple URLSession extension, and all tests would pass.
 
7- Footer Notes on Invalid Cases
*/

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
        XCTAssertEqual(observedRequest?.httpMethod, "GET")
    }
    
    // MARK: Error Cases
    
    func test_getFromURL_onRequestError_fails() async {
        // Needs to be NSError
        let expectedError = NSError(domain: "failsOnRequestError", code: 13)
        let url = anyURL()
     
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)
        let sut = makeSUT()
        
        await assertFailsWithNSError(expectedError) {
            _ = try await sut.getData(from: url)
        }
    }
    
    func test_getFromURL_onNonHTTPURLResponse_failsWithURLError() async {
        let validReturn = Data()
        let url = anyURL()
        let nonHTTPResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
     
        URLProtocolStub.stub(data: validReturn, response: nonHTTPResponse, error: nil)
        let sut = makeSUT()
        
        await assertFailsWith(URLError(.cannotParseResponse)) {
            _ = try await sut.getData(from: url)
        }
    }
    
    // MARK: Success Cases
    
    func test_getFromURL_withNilDataOnHTTPURLResponse_succeedsWithEmptyData() async throws {
        let returnedNilData: Data? = nil
        let expectedEmptyData = Data()
        let url = anyURL()
        let validResponse = HTTPURLResponse(url: url,
                                            statusCode: 200, httpVersion: nil, headerFields: nil)!
     
        URLProtocolStub.stub(data: returnedNilData, response: validResponse, error: nil)
       
        try await assertGetData(willReturn: (data: expectedEmptyData, response: validResponse))
    }
    
    func test_getFromURL_withDataOnHTTPURLResponse_succeeds() async throws {
        let expectedReturn = makeImages().data
        let url = anyURL()
        let validResponse = HTTPURLResponse(url: url,
                                            statusCode: 200, httpVersion: nil, headerFields: nil)!
     
        URLProtocolStub.stub(data: expectedReturn, response: validResponse, error: nil)
        
        try await assertGetData(willReturn: (data: expectedReturn, response: validResponse))
    }
}

// MARK: - Helpers
private extension URLSessionHTTPClientTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        
        trackForMemoryLeaks(sut)
        
        return sut
    }
    
    func assertFailsWithNSError(_ expectedNSError: NSError,
                                action: () async throws -> Void,
                                file: StaticString = #filePath, line: UInt = #line) async {
        do {
            try await action()
            XCTFail("Expected Error but returned successfully instead", file: file, line: line)
        } catch let error as NSError {
            XCTAssertEqual(error.code, expectedNSError.code, file: file, line: line)
            XCTAssertEqual(error.domain, expectedNSError.domain, file: file, line: line)
        } catch {
            XCTFail("Should throw expectedError but threw \(error) instead", file: file, line: line)
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
            XCTFail("Should throw expectedError but threw \(error) instead", file: file, line: line)
        }
    }
    
    func assertGetData(willReturn expectedReturn: (data: Data, response: HTTPURLResponse),
                       file: StaticString = #filePath, line: UInt = #line) async throws {
        let url = anyURL()
        let sut = makeSUT()

        do {
            let receivedReturn = try await sut.getData(from: url)
            
            XCTAssertEqual(receivedReturn.data, expectedReturn.data, file: file, line: line)
            XCTAssertEqual(receivedReturn.response.url, expectedReturn.response.url, file: file, line: line)
            XCTAssertEqual(receivedReturn.response.statusCode, expectedReturn.response.statusCode, file: file, line: line)
        } catch {
            XCTFail("Should succeed but threw \(error) instead", file: file, line: line)
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

/* Alternative Approach - Protocol-based mocking (not applied)

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
 
*/

/* FOOTER NOTES - Testing invalid cases
 
 When using completion, because the own return of dataTask contains 3 optionals (Data?, URLReponse?, Error?) we need to validate assumptions to understand how this framework works. That's why was mada a test to avoid all invalid case scenarios (while also asserting that the return will be HTTPURLResponse instead of URLResponse).
 
 Due to the nature of the Async/Await that is no longer needded since these invalid scenarios are not possible to be represented, only through the Stub.
 The following test was done as an exersise and the HTTPURLResponse was done in a separate test.
 
 // MARK: Documentation
 
 // Test as documentation: assert that Stub will not behave differenlty as it should
 func test_getFromURL_failsOnAllInvalidRepresentationCases() async {
     let anyData = anyData()
     let anyResponse = URLResponse()
     let anyError = anyErrorErased("Any Error")
     
     let expectedError: NSError = URLProtocolStub.invalidRepresentationError
     
     let invalidStubs: [(Data?, URLResponse?, Error?)] = [
         (nil, nil, nil),
         (anyData, anyResponse, anyError),
         (anyData, nil, nil),
         // (nil, anyResponse, nil), nil data and response is valid scenario
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
 
 // MARK: - In the URLProtocolStub -> could have made a helper to represent all these scenarios
 
 // MARK: - Helpers
 
 static let invalidRepresentationError = NSError(domain: "Invalid Representation Error", code: 1)
 
 static func isValidStub() -> Bool {
     // Represent the invalid cases here
     switch (stub?.data, stub?.response, stub?.error) {
     case (nil, nil, nil),
          (.some(_), .some(_), .some(_)),
          (.some(_), nil, nil),
         // (nil, .some(_), nil), nil data and response is valid scenario
          (nil, .some(_), .some(_)),
          (.some(_), nil, .some(_)):
         return false
     default:
         return true
     }
 }
 
 */
