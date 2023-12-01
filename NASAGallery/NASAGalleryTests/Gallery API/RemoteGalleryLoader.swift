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
    
    func test_load_requestDataFromURL() async {
        let url = URL(string: "b-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        try? await sut.load()
        
        XCTAssertEqual(client.receivedMessages, [.load(url)])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        try? await sut.load()
        try? await sut.load()

        XCTAssertEqual(client.receivedMessages, [.load(url), .load(url)])
    }
    
    func test_load_deliversErrorOnClientError() async {
        let (sut, client) = makeSUT()
        client.completeWith(error: .connectivity)
        
        var capturedErrors: [RemoteGalleryLoader.Error] = []
        do {
            try await sut.load()
        } catch let error as RemoteGalleryLoader.Error {
            capturedErrors.append(error)
        } catch {
            XCTFail("Should return RemoteGalleryLoader.Error but returned \(error) instead")
        }
        
        XCTAssertEqual(capturedErrors, [.connectivity])
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
        
        func get(from url: URL) async throws {
            receivedMessages.append(.load(url))
            
            if let error = returningError {
                throw error
            }
        }
        
        // MARK: - Completions
        
        var returningError: Error?
        
        public func completeWith(error: RemoteGalleryLoader.Error) {
            returningError = error
        }
    }
}
