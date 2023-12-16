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
    
    func test_getData_firesSessionDataFromURL() async throws {
        let url = anyURL()
        let sessionSpy = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: sessionSpy)
        
        try await sut.getData(from: url)
        
        XCTAssertEqual(sessionSpy.receivedMessages, [.data(url)])
    }
}

protocol URLSessionProtocol {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol { }

// MARK: - Spy

final class URLSessionSpy: URLSessionProtocol {
    enum ReceivedMessage: Equatable {
        case data(URL)
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        receivedMessages.append(.data(url))
        return (Data(), URLResponse())
    }
}
