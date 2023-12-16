//
//  URLSessionHTTPClientTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 16/12/23.
//

import XCTest

/* NOTE Author Notes
 
 1- The first TDD approach was through subclassing URLSession.
 However the "data(from url: URL) async" is declared in a swift extension and Swift extensions cannot be overridden because they are not part of the original class declaration
 
 */

/* NOTE TODOs
 
*/

final class URLSessionHTTPClient {
    // Note how must be the protocol in production code and not the real URLSession
    let session: URLSessionProtocol
    
    init(session: URLSessionProtocol) {
        self.session = session
    }
    
    func getData(from url: URL) async throws {
        _ = try await session.data(from: url)
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getData_firesSessionDataFromURL() async {
        let url = anyURL()
        let sessionSpy = URLSessionSpy()
        sessionSpy.stub(url: url, error: anyError())
        let sut = URLSessionHTTPClient(session: sessionSpy)
        
        try? await sut.getData(from: url)
        
        XCTAssertEqual(sessionSpy.receivedMessages, [.data(url)])
    }
    
    func test_getFromURL_failsOnRequestError() async {
        let url = anyURL()
        let expectedError = anyError("Expected Error")
        let sessionSpy = URLSessionSpy()
        sessionSpy.stub(url: url, error: expectedError)
        let sut = URLSessionHTTPClient(session: sessionSpy)

        do {
            try await sut.getData(from: url)
            XCTFail("Expected Error but returned successfully instead")
        } catch {
            XCTAssertEqual(error as? AnyError, expectedError as? AnyError)
        }
    }
}

protocol URLSessionProtocol {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol { }

// MARK: - Spy

final class URLSessionSpy: URLSessionProtocol {
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
