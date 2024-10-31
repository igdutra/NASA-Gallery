//
//  ValidateGalleryFromCacheUseCaseTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 22/03/24.
//

import XCTest
import NASAGallery

/* Author Notes on ValidateGalleryFromCacheUseCaseTests
 
 ### 3. Validate Gallery Cache Use Case

 #### Primary course:
 1. Execute "Validate Cached APOD Gallery" command.
 2. System retrieves gallery data from cache.
 3. System validates cache age againts maximum age: verify if it is less than 2 days old.

 #### Retrieval error course (sad path):
 1. System deletes cache.

 #### Expired cache course (sad path):
 1. System deletes cache.
*/
final class ValidateGalleryFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.receivedMessages, [])
    }

    func test_validateCache_onRetrievalError_deletesCache() async {
        let (sut, spy) = makeSUT()
        spy.stub(retrivalError: AnyError(message: "Retrival Error"))
        
        try? await sut.validateCache()
        
        XCTAssertEqual(spy.receivedMessages, [.retrieve, .delete])
    }
    
    func test_validateCache_onNonExpiredCache_doesNotDeleteCache() async throws {
        let (sut, spy) = makeSUT()
        let lessThanMaxOldTimestamp = cacheMaxAgeLimitTimestamp.adding(seconds: 1)
        let expectedCache = LocalGalleryCache(gallery: uniqueLocalImages().local, timestamp: lessThanMaxOldTimestamp)
        spy.stub(retrivalReturn: expectedCache)
        
        try await sut.validateCache()
        
        XCTAssertEqual(spy.receivedMessages, [.retrieve])
    }
    
    func test_validadeCache_onCacheExpiration_deletesCache() async throws {
        let (sut, spy) = makeSUT()
        let onExpirationCache = LocalGalleryCache(gallery: uniqueLocalImages().local, timestamp: cacheMaxAgeLimitTimestamp)
        spy.stub(retrivalReturn: onExpirationCache)
        
        try await sut.validateCache()
        
        XCTAssertEqual(spy.receivedMessages, [.retrieve, .delete])
    }
    
    func test_validateCache_onExpiredCache_deletesCache() async throws {
        let (sut, spy) = makeSUT()
        let moreThanMaxOldTimestamp = cacheMaxAgeLimitTimestamp.adding(seconds: -1)
        let expiredCache = LocalGalleryCache(gallery: uniqueLocalImages().local, timestamp: moreThanMaxOldTimestamp)
        spy.stub(retrivalReturn: expiredCache)
        
        try await sut.validateCache()
        
        XCTAssertEqual(spy.receivedMessages, [.retrieve, .delete])
    }
}

// MARK: - Helpers
private extension ValidateGalleryFromCacheUseCaseTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalGalleryLoader, store: GalleryStoreSpy) {
        let store = GalleryStoreSpy()
        let sut = LocalGalleryLoader(store: store)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        
        return (sut, store)
    }
}

