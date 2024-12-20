//
//  LoadGalleryFromRemoteUseCaseTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 20/11/23.
//

import XCTest
import NASAGallery

/* Author Notes on RemoteGalleryLoaderTests
 
- benchtest test_load_deliversErrorOnNon200HTTPResponse
Why? because a new instance of SUT is created at each for loop interation
Result: Test Case '-[NASAGalleryTests.RemoteGalleryLoaderTests test_load_deliversErrorOnNon200HTTPResponse]' passed (0.001 seconds).
Same as the other ones so it's fine
 
- test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated
 Caio and Mike always perform this test when testing async code.
This test is to asset that the classic * guard self != nil else { return } * was added
However, due to the async await nature "transforming" the code into sync, this test is not needed.
On the other hand, one test that SHOULD be introduced is to be aware of *Reentrancy*
In this context of RemoteGalleryLoader is not needed, but when testing things in integration we should be aware of
* Cache Scenarios
* UI Multiple Updates
 
- makeSUT Map vs If
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

- Avoid makeSUT at the test call site
This is open to discussion however the goal here was to make the tests more redable
Because we need to stub everything upfront, we need to create the SUT with the predefined behavior.
I thought that wrapping the SUT creation by not expliciting telling what is the client Result upfront but actually at the name of the assertion
(makeSUT(withClientFailure vs toThrow expectedError: _, whenClientReturnsError clientError: )
is a win in redability.
But this is open as I write more tests a pattern could emerge.

- Spy vs Stub
This Spy is not "pure" a spy: it not only captures values, but also outputs pre-defined reponses!
Must be this way due to Async/Await nature, we can't capture values and use them when we want.

*/

final class LoadGalleryFromRemoteUseCaseTests: XCTestCase {
    
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
    
    func test_load_onClientError_failsWithConnectivityError() async {
        
        await assertLoad(toThrow: .connectivity,
                         whenClientReturnsError: .connectivity)
    }
    
    func test_load_onNon200HTTPResponse_failsWithConnectivityError() async {
        let samples = [199, 201, 300, 400, 500]
        
        // Note: .forEach() method expects a synchronous closure
        for code in samples {
            let clientResponse = SuccessResponse(response: HTTPURLResponse(statusCode: code), data: Data())
            await assertLoad(toThrow: .invalidData(underlying: URLError(.badServerResponse)),
                             whenClientReturnsWithResponse: clientResponse)
        }
    }
        
    func test_load_on200HTTPResponseWithInvalidJSON_failsWithInvalidDataError() async {
        let invalidJSON = invalidJSON()
        let clientResponse = SuccessResponse(response: HTTPURLResponse(statusCode: 200), data: invalidJSON)
        // Noto: this is not the real issue.
        let underlyingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid JSON"))
        
        await assertLoad(toThrow: .invalidData(underlying: underlyingError),
                         whenClientReturnsWithResponse: clientResponse)
    }
    
    // MARK: - Happy Path
    
    func test_load_on200HTTPResponseWithEmptyJSONList_succeedsWithNoItems() async {
        let emptyJSON = Data("[]".utf8)
        let expectedLoadReturn: [GalleryImage] = []
        let clientResponse = SuccessResponse(response: HTTPURLResponse(statusCode: 200), data: emptyJSON)
        
        
        await assertLoadDelivers(expectedLoadReturn,
                                 whenClientReturnsWithSuccess: clientResponse)
    }
    
    func test_load_on200HTTPResponseWithJSONItems_succeedsWithItems() async {
        let (expectedItems, expectedJSONData) = makeImages()
        let clientResponse = SuccessResponse(response: HTTPURLResponse(statusCode: 200), data: expectedJSONData)
        
        await assertLoadDelivers(expectedItems,
                                 whenClientReturnsWithSuccess: clientResponse)
    }
}
// MARK: - Helpers

private extension LoadGalleryFromRemoteUseCaseTests {
    
    typealias SuccessResponse = HTTPClientSpy.SuccessResponse
    
    func makeSUT(url: URL = anyURL(),
                 withSuccessfulClientResponse response: SuccessResponse? = nil,
                 withClientFailure error: RemoteGalleryLoader.Error? = nil,
                 file: StaticString = #filePath, line: UInt = #line) -> RemoteGalleryLoader {

        let successResult = response.map(HTTPClientSpy.Result.success)
        let failureResult = error.map(HTTPClientSpy.Result.failure)
        let result = successResult ?? failureResult ?? .failure(.connectivity) // Default Value

        let client = HTTPClientSpy(result: result)
        let sut = RemoteGalleryLoader(url: url, client: client)
        
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    // MARK: - Assertions

    func assertLoad(toThrow expectedError: RemoteGalleryLoader.Error,
                    whenClientReturnsError clientError: RemoteGalleryLoader.Error,
                    file: StaticString = #filePath, line: UInt = #line) async {
        let sut = makeSUT(withClientFailure: clientError, file: file, line: line)
        
        await assertLoadFrom(sut,
                             toThrow: expectedError)
    }
    
    func assertLoad(toThrow expectedError: RemoteGalleryLoader.Error,
                    whenClientReturnsWithResponse clientResponse: HTTPClientSpy.SuccessResponse,
                    file: StaticString = #filePath, line: UInt = #line) async {
        let sut = makeSUT(withSuccessfulClientResponse: clientResponse, file: file, line: line)
        
        await assertLoadFrom(sut, toThrow: expectedError, file: file, line: line)
    }

    func assertLoadFrom(_ sut: RemoteGalleryLoader,
                        toThrow expectedError: RemoteGalleryLoader.Error,
                        file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await sut.load()
            XCTFail("Expected RemoteGalleryLoader.Error but returned successfully instead")
        } catch let error as RemoteGalleryLoader.Error {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Expected \(expectedError) but returned \(error) instead", file: file, line: line)
        }
    }
    
    func assertLoadDelivers(_ expectedImages: [GalleryImage],
                            whenClientReturnsWithSuccess clientResponse: HTTPClientSpy.SuccessResponse,
                            file: StaticString = #filePath, line: UInt = #line) async {
        let sut = makeSUT(withSuccessfulClientResponse: clientResponse, file: file, line: line)
        
        do {
            let images = try await sut.load()
            XCTAssertEqual(images, expectedImages)
        } catch {
            XCTFail("Expected Success but returned \(error) instead", file: file, line: line)
        }
    }
}

// MARK: - Spy

private extension LoadGalleryFromRemoteUseCaseTests {
    class HTTPClientSpy: HTTPClient {
        // Note: ReceivedMessage is the method signature
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
        
        func getData(from url: URL) async throws -> (data: Data, response: HTTPURLResponse) {
            receivedMessages.append(.load(url))
            switch result {
            case let .success(spyResponse):
                return (spyResponse.data, spyResponse.response)
            case let .failure(error):
                throw error
            }
        }
    }
}

// MARK: - Error Extension

extension RemoteGalleryLoader.Error: Equatable {
    // Note: TradeOff: compare in the tests just the type, but for debugging this is helpful information
    public static func == (lhs: RemoteGalleryLoader.Error, rhs: RemoteGalleryLoader.Error) -> Bool {
        switch (lhs, rhs) {
        case (.connectivity, .connectivity):
            return true
        case (.invalidData, .invalidData):
            return true
        default:
            return false
        }
    }
}
