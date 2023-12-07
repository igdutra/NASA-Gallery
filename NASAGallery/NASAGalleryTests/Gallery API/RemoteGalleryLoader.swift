//
//  RemoteGalleryLoaderTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 20/11/23.
//

import XCTest
import NASAGallery

/* TODOs
 
 1- Refactor the makeSUT to not return client.
 2- Inoumeros refactors to make
    - remove all references to results. case client is better to wrap in result, use helper methods
 3- don't forget to create production mapper (without breaking testes! :) )
 4- crete 2 expectReturns: one when trowing func another on positive result
    makes sense to create 2 expected returns because the do/catch assertions will be different!
 5- enhance fixture methods to return at least 2 fixtures (and don't use only default values)
 6- the ideia is: remove all "RESULT" reference from tests, use and abuse of TEST DSLs (the result type lives in the test alone!)
 
 */

final class RemoteGalleryLoaderTests: XCTestCase {
    
    typealias LoaderResult = Result<[GalleryItem], RemoteGalleryLoader.Error>
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.receivedMessages.isEmpty)
    }
    
    func test_load_requestDataFromURL() async {
        let url = anyURL("b-url")
        let (sut, client) = makeSUT(url: url)
        
        _ = try? await sut.load()
        
        XCTAssertEqual(client.receivedMessages, [.load(url)])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() async {
        let url = anyURL("a-given-url")
        let (sut, client) = makeSUT(url: url)
        
        _ = try? await sut.load()
        _ = try? await sut.load()
        
        XCTAssertEqual(client.receivedMessages, [.load(url), .load(url)])
    }
    
    // MARK: - Error Cases
    
    func test_load_deliversErrorOnClientError() async {
       
       await expectSUTLoad(toThrow: .connectivity,
                           whenClientReturns: .failure(.connectivity))
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() async {
        let samples = [199, 201, 300, 400, 500]
      
        // Note: .forEach() method expects a synchronous closure
        for code in samples {
            let expectedResult = clientSuccess(statusCode: code, data: Data())
            await expectSUTLoad(toThrow: .invalidData,
                                whenClientReturns: .success(expectedResult))
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() async {
        let invalidJSON = invalidJSON()
        let expectedResult = clientSuccess(statusCode: 200, data: invalidJSON)
     
        await expectSUTLoad(toThrow: .invalidData,
                            whenClientReturns: .success(expectedResult))
    }
    
    // MARK: - Happy Path
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() async {
        let emptyJSON = Data("[]".utf8)
        let expectedLoadReturn: [GalleryItem] = []
        let clientResult = clientSuccess(statusCode: 200, data: emptyJSON)
        
        let (sut, _) = makeSUT(result: .success(clientResult))
        
        var capturedResults: [LoaderResult] = []
        
        do {
            let items = try await sut.load()
            capturedResults.append(.success(items))
        } catch {
            XCTFail("Expected Success but returned \(error) instead")
        }
        
        XCTAssertEqual(capturedResults, [.success([])])
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() async {
        let (expectedItems, expectedJSONData) = makeItems()
        let clientResult = clientSuccess(statusCode: 200, data: expectedJSONData)
        
        let (sut, _) = makeSUT(result: .success(clientResult))
        
        var capturedItems: [GalleryItem] = []
        
        do {
            let items = try await sut.load()
            capturedItems.append(contentsOf: items)
        } catch {
            XCTFail("Expected Success but returned \(error) instead")
        }
        
        XCTAssertEqual(capturedItems, expectedItems)
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
    
    func clientSuccess(statusCode: Int, data: Data) -> HTTPClientSpy.SpyResponse {
        HTTPClientSpy.SpyResponse(response: HTTPURLResponse(statusCode: statusCode), data: data)
    }
    
    // MARK: Factories
    
    func makeItems() -> ([GalleryItem], Data) {
        let item1 = makeGalleryItemFixture(title: "First Item")
        let item2 = makeGalleryItemFixture(urlString: "image1", explanation: "This is the second Item")
        let items = [item1, item2]
        let data = makeGalleryJSONData(items)
        
        return (items, data)
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
