//
//  RemoteGalleryLoaderTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 20/11/23.
//

import XCTest
import NASAGallery

/* TODOs
 
 2- Inoumeros refactors to make
 - remove all references to results. case client is better to wrap in result, use helper methods
 3- don't forget to create production mapper (without breaking testes! :) )
 4- crete 2 expectReturns: one when trowing func another on positive result
 makes sense to create 2 expected returns because the do/catch assertions will be different!
 5- enhance fixture methods to return at least 2 fixtures (and don't use only default values)
 6- the ideia is: remove all "RESULT" reference from tests, use and abuse of TEST DSLs (the result type lives in the test alone!)
 
 */

final class RemoteGalleryLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy(result: .failure(.connectivity))
        let _ = RemoteGalleryLoader(url: anyURL(), client: client)
        
        XCTAssertTrue(client.receivedMessages.isEmpty)
    }
    
    func test_load_requestDataFromURL() async {
        let url = anyURL("b-url")
        let client = HTTPClientSpy(result: .failure(.connectivity))
        let sut = RemoteGalleryLoader(url: url, client: client)
        
        _ = try? await sut.load()
        
        XCTAssertEqual(client.receivedMessages, [.load(url)])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() async {
        let url = anyURL("a-given-url")
        let client = HTTPClientSpy(result: .failure(.connectivity))
        let sut = RemoteGalleryLoader(url: url, client: client)
        
        _ = try? await sut.load()
        _ = try? await sut.load()
        
        XCTAssertEqual(client.receivedMessages, [.load(url), .load(url)])
    }
    
    // MARK: - Error Cases
    
    func test_load_deliversErrorOnClientError() async {
        
        await expectSUTLoadMethod(toThrow: .connectivity,
                                  whenClientReturnsError: .connectivity)
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() async {
        let samples = [199, 201, 300, 400, 500]
        
        // Note: .forEach() method expects a synchronous closure
        for code in samples {
            let clientResponse = SuccessResponse(response: HTTPURLResponse(statusCode: code), data: Data())
            await expectSUTLoad(toThrow: .invalidData,
                                whenClientReturnsSuccessfullyWith: clientResponse)
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() async {
        let invalidJSON = invalidJSON()
        let clientResponse = SuccessResponse(response: HTTPURLResponse(statusCode: 200), data: Data())
        
        await expectSUTLoad(toThrow: .invalidData,
                            whenClientReturnsSuccessfullyWith: clientResponse)
    }
    
    // MARK: - Happy Path
    
    typealias LoaderResult = Result<[GalleryItem], RemoteGalleryLoader.Error>
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() async {
        let emptyJSON = Data("[]".utf8)
        let expectedLoadReturn: [GalleryItem] = []
        let clientResponse = SuccessResponse(response: HTTPURLResponse(statusCode: 200), data: emptyJSON)
        
        let sut = makeSUT(withSuccessfulClientResponse: clientResponse)
        
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
        let clientResponse = SuccessResponse(response: HTTPURLResponse(statusCode: 200), data: expectedJSONData)
        
        let sut = makeSUT(withSuccessfulClientResponse: clientResponse)
        
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
    
    typealias SuccessResponse = HTTPClientSpy.SuccessResponse
    
    func makeSUT(url: URL = anyURL(),
                 withSuccessfulClientResponse response: SuccessResponse? = nil,
                 withClientFailure error: RemoteGalleryLoader.Error? = nil) -> RemoteGalleryLoader {

        let successResult = response.map(HTTPClientSpy.Result.success)
        let failureResult = error.map(HTTPClientSpy.Result.failure)
        let result = successResult ?? failureResult ?? .failure(.connectivity) // Default Value
        
        /* NOTE Map vs If
         
         This map approach is a replacement of the if/else chain below
         if let response = response {
             result = .success(response)
         } else if let error = error {
             result = .failure(error)
         } else {
             result = .failure(.connectivity)
         }
         which according to bench tests are close to 2x faster
         makeSUT with If: 0.034626007080078125 seconds
         makeSUT with Map: 0.019369006156921387 seconds
         
         */

        let client = HTTPClientSpy(result: result)
        return RemoteGalleryLoader(url: url, client: client)
    }
    
    // Note: first implementation of the expect method.
    // Wait for more testst to come, maybe just add a helper for the do/catch block and let the rest in the test scope.
    // XCTAsyncAssertThrowingFunction(...)
    func expectSUTLoad(toThrow expectedError: RemoteGalleryLoader.Error,
                       whenClientReturnsSuccessfullyWith clientResponse: HTTPClientSpy.SuccessResponse) async {
        let sut = makeSUT(withSuccessfulClientResponse: clientResponse)
        
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
    
    // MARK: - Assertions
    
    func expectSUTLoadMethod(toThrow expectedError: RemoteGalleryLoader.Error,
                             whenClientReturnsError clientError: RemoteGalleryLoader.Error) async {
        let sut = makeSUT(withClientFailure: clientError)
        
        var capturedErrors: [RemoteGalleryLoader.Error] = []
        do {
            _ = try await sut.load()
            XCTFail("Expected RemoteGalleryLoader.Error but returned successfully instead")
        } catch let error as RemoteGalleryLoader.Error {
            capturedErrors.append(error)
        } catch {
            XCTFail("Expected RemoteGalleryLoader.Error but returned \(error) instead")
        }
        
        XCTAssertEqual(capturedErrors, [expectedError])
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
        // ReceivedMessages is the method signature
        enum ReceivedMessage: Equatable {
            case load(URL)
        }
        
        struct SuccessResponse: Equatable {
            let response: HTTPURLResponse
            let data: Data
        }
        
        typealias Result = Swift.Result<SuccessResponse, RemoteGalleryLoader.Error>
        
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
