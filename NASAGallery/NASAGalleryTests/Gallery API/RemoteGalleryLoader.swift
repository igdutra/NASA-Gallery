//
//  RemoteGalleryLoaderTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 20/11/23.
//

import XCTest
import NASAGallery


final class RemoteGalleryLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.receivedMessages.isEmpty)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "b-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        
        XCTAssertEqual(client.receivedMessages, [.load(url)])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load()
        sut.load()

        XCTAssertEqual(client.receivedMessages, [.load(url), .load(url)])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "a-url.com")!) -> (sut: RemoteGalleryLoader, spy: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteGalleryLoader(url: url, client: client)
        return (sut, client)
    }
}

// MARK: - Spy

private extension RemoteGalleryLoaderTests {
    class HTTPClientSpy: HTTPClient {
        enum ReceivedMessage: Equatable {
            case load(URL)
        }
        
        private(set) var receivedMessages = [ReceivedMessage]()
        
        func get(from url: URL) {
            receivedMessages.append(.load(url))
        }
    }
}
