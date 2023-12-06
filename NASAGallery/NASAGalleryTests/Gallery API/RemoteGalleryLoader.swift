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
       
       await expectSUTLoad(toThrow: .connectivity,
                           whenClientReturns: .failure(.connectivity))
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() async {
        let samples = [199, 201, 300, 400, 500]
      
        
        // Note: .forEach() method expects a synchronous closure
        for code in samples {
            let expectedResult = HTTPClientSpy.SpyResponse(response: HTTPURLResponse(statusCode: code), data: Data())
            await expectSUTLoad(toThrow: .invalidData,
                                whenClientReturns: .success(expectedResult))
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() async {
        let invalidJSON = invalidJSON()
        let expectedResult = HTTPClientSpy.SpyResponse(response: HTTPURLResponse(statusCode: 200), data: invalidJSON)
        
        await expectSUTLoad(toThrow: .invalidData,
                            whenClientReturns: .success(expectedResult))
    }
}
// MARK: - Helpers

private extension RemoteGalleryLoaderTests {
    
    func makeSUT(url: URL = anyURL(),
                 result: HTTPClientSpy.Result = .failure(.connectivity)) -> (sut: RemoteGalleryLoader, spy: HTTPClientSpy) {
        let client = HTTPClientSpy(result: result)
        let sut = RemoteGalleryLoader(url: url, client: client)
        return (sut, client)
    }
    
    // Note: first implementation of the expect method.
    // Wait for more testst to come, maybe just add a helper for the do/catch block and let the rest in the test scope.
    // XCTAsyncAssertThrowingFunction(...)
    func expectSUTLoad(toThrow expectedError: RemoteGalleryLoader.Error,
                       whenClientReturns clientResult: HTTPClientSpy.Result) async {
        // TODO: possible to remove client from makeSUT, since results are stubbed upfront
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
        
        XCTAssertEqual(capturedResults, [.failure(expectedError)])
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
        
        struct SpyResponse: Equatable {
            let response: HTTPURLResponse
            let data: Data
        }
        
        typealias Result = Swift.Result<SpyResponse, RemoteGalleryLoader.Error>
        
        private(set) var receivedMessages = [ReceivedMessage]()
        private let result: Result
        
        public init(result: Result) {
            self.result = result
        }
        
        // MARK: - HTTPClient
        
        func get(from url: URL) async throws -> (HTTPURLResponse, Data) {
            receivedMessages.append(.load(url))
            switch result {
            case let .success(spyResponse):
                return (spyResponse.response, spyResponse.data)
            case let .failure(error):
                throw error
            }
        }
    }
    
}
