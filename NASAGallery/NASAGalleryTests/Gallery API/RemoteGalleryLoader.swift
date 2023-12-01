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
        let url = anyURL("b-url")
        let (sut, client) = makeSUT(url: url)
        
        try? await sut.load()
        
        XCTAssertEqual(client.receivedMessages, [.load(url)])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() async {
        let url = anyURL("a-given-url")
        let (sut, client) = makeSUT(url: url)

        try? await sut.load()
        try? await sut.load()

        XCTAssertEqual(client.receivedMessages, [.load(url), .load(url)])
    }
    
    func test_load_deliversErrorOnClientError() async {
        // TODO: possible to remove client from makeSUT, since results are stubbed upfront
        let clientResult: HTTPClientSpy.Result = .failure(.connectivity)
        let (sut, _) = makeSUT(result: clientResult)
        
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
    
    func test_load_deliversErrorOnNon200HTTPResponse() async {
        let samples = [199, 201, 300, 400, 500]
        
        // Note: .forEach() method expects a synchronous closure
        for code in samples {
            // TODO: possible to remove client from makeSUT, since results are stubbed upfront
            let clientResult: HTTPClientSpy.Result = .success(HTTPURLResponse(statusCode: code))
            let (sut, _) = makeSUT(result: clientResult)
            
            var capturedResults: [HTTPClientSpy.Result] = []
            do {
                _ = try await sut.load()
                XCTFail("Expected RemoteGalleryLoader.Error but returned successfully instead")
            } catch let error as RemoteGalleryLoader.Error {
                capturedResults.append(.failure(error))
            } catch {
                XCTFail("Expected RemoteGalleryLoader.Error but returned \(error) instead")
            }
            
            print("code", code)
            XCTAssertEqual(capturedResults, [.failure(RemoteGalleryLoader.Error.invalidData)], "Expected .invalidData error for HTTP status code \(code)")
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = anyURL(),
                         result: HTTPClientSpy.Result = .failure(.connectivity)) -> (sut: RemoteGalleryLoader, spy: HTTPClientSpy) {
        let client = HTTPClientSpy(result: result)
        let sut = RemoteGalleryLoader(url: url, client: client)
        return (sut, client)
    }
}

// MARK: - Spy

/* NOTE Spy vs Stub
 
 This Spy is not "pure" a spy: it not only captures values, but also outputs pre-defined reponses!
 */
private extension RemoteGalleryLoaderTests {
    class HTTPClientSpy: HTTPClient {
        enum ReceivedMessage: Equatable {
            case load(URL)
        }
        
        typealias Result = Swift.Result<HTTPURLResponse, RemoteGalleryLoader.Error>
        
        private(set) var receivedMessages = [ReceivedMessage]()
        private let result: Result
        
        public init(result: Result) {
            self.result = result
        }
        
        // MARK: - HTTPClient
        
        func get(from url: URL) async throws -> HTTPURLResponse {
            receivedMessages.append(.load(url))
            return try result.get()
        }
    }
}
