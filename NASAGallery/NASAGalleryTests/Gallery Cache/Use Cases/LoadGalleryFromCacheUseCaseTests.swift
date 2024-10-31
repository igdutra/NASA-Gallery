//
//  LoadGalleryFromCacheUseCaseTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 15/03/24.
//

import XCTest
import NASAGallery

/* Author Notes on LoadGalleryFromCacheUseCaseTests
 - Load Galley from Cache Use Case is the LocalStore load command, which will conform to `GalleryLoader` protocol
 - LocalGalleryLoader was also choosen to be the component where this functionality would reside, but this could easily be swapped to a separate space!
    - thus the test_init_doesNotMessageStoreUponCreation appears to be duplicated, but it is not.

 ### Load APOD Gallery from Cache Use Case

 #### Primary course:
 1. Execute "Retrieve Cached APOD Gallery" command.
 2. System retrieves APOD Gallery data from cache.
 3. System validates cache age againts maximum age: verify if it is less than 2 days old.
 4. System creates APOD Gallery from valid cached data.
 5. System delivers APOD Gallery.

 #### Retrieval error course (sad path):
 1. System deletes cache.
 2. System delivers error.

 #### Expired cache course (sad path):
 1. System deletes cache.
 2. System delivers no gallery.

 #### Empty cache course (sad path):
 1. System delivers no APOD gallery.
*/

final class LoadGalleryFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.receivedMessages, [])
    }
    
    func test_load_requestsCacheRetrival() async {
        let (sut, spy) = makeSUT()
        
        _ = try? await sut.load()
        
        XCTAssertEqual(spy.receivedMessages, [.retrieve])
    }
    
    // MARK: - Error Cases
    
    func test_load_onRetrivalError_fails() async {
        let (sut, spy) = makeSUT()
        let retrivalError = AnyError(message: "Retrival Error")
        spy.stub(retrivalError: retrivalError)
        
        do {
            _ = try await sut.load()
            XCTFail("Load should fail on retrival error")
        } catch let error as AnyError {
            XCTAssertEqual(error, retrivalError)
        } catch {
            XCTFail("Expected error to be the retrival error")
        }
    }
    
    func test_load_onEmptyCache_deliversNoImages() async throws {
        let (sut, spy) = makeSUT()
        let expectedImages = uniqueLocalImages()
        let expectedCache = LocalGalleryCache(gallery: expectedImages.local, timestamp: Date())
        spy.stub(retrivalReturn: expectedCache)
        
        let cache = try await sut.load()
        
        XCTAssertEqual(cache, expectedImages.images)
    }
    
    // MARK: - Validating and Triangulation
    
    // Succeess case
    func test_load_onNonExpiredCache_succeesdsWithCachedImages() async throws {
        let (sut, spy) = makeSUT()
        let lessThanMaxOldTimestamp = cacheMaxAgeLimitTimestamp.adding(seconds: 1)
        let expectedImages = uniqueLocalImages()
        let expectedCache = LocalGalleryCache(gallery: expectedImages.local, timestamp: lessThanMaxOldTimestamp)
        spy.stub(retrivalReturn: expectedCache)
        
        let cache = try await sut.load()
        
        XCTAssertEqual(cache, expectedImages.images)
    }
    
    func test_load_onCacheExpiration_failsWithEmptyImages() async throws {
        let (sut, spy) = makeSUT()
        let expiredCache = LocalGalleryCache(gallery: uniqueLocalImages().local, timestamp: cacheMaxAgeLimitTimestamp)
        spy.stub(retrivalReturn: expiredCache)
        
        let cache = try await sut.load()
        
        XCTAssertEqual(cache, [])
    }
    
    func test_load_onExpiredCache_failsWithEmptyImages() async throws {
        let (sut, spy) = makeSUT()
        let moreThanMaxOldTimestamp = cacheMaxAgeLimitTimestamp.adding(seconds: -1)
        let expiredCache = LocalGalleryCache(gallery: uniqueLocalImages().local, timestamp: moreThanMaxOldTimestamp)
        spy.stub(retrivalReturn: expiredCache)
        
        let cache = try await sut.load()
        
        XCTAssertEqual(cache, [])
    }
    
    // MARK: - Side Effects Free
    
    func test_load_onRetrievalError_hasNoSideEffects() async {
        let (sut, spy) = makeSUT()
        spy.stub(retrivalError: AnyError(message: "Retrival Error"))
        
        _ = try? await sut.load()
        
        XCTAssertEqual(spy.receivedMessages, [.retrieve])
    }
    
    func test_load_onEmptyCache_hasNoSideEffects() async {
        let (sut, spy) = makeSUT()
        let emptyCache = LocalGalleryCache(gallery: [], timestamp: Date())
        spy.stub(retrivalReturn: emptyCache)
        
        _ = try? await sut.load()
        
        XCTAssertEqual(spy.receivedMessages, [.retrieve])
    }
    
    func test_load_onNonExpiredCache_hasNoSideEffects() async {
        let (sut, spy) = makeSUT()
        let lessThanMaxOldTimestamp = cacheMaxAgeLimitTimestamp.adding(seconds: 1)
        let expectedCache = LocalGalleryCache(gallery: uniqueLocalImages().local, timestamp: lessThanMaxOldTimestamp)
        spy.stub(retrivalReturn: expectedCache)
        
        _ = try? await sut.load()
        
        XCTAssertEqual(spy.receivedMessages, [.retrieve])
    }
    
    func test_load_onCacheExpiration_hasNoSideEffects() async {
        let (sut, spy) = makeSUT()
        let onExpirationCache = LocalGalleryCache(gallery: uniqueLocalImages().local, timestamp: cacheMaxAgeLimitTimestamp)
        spy.stub(retrivalReturn: onExpirationCache)
        
        _ = try? await sut.load()
        
        XCTAssertEqual(spy.receivedMessages, [.retrieve])
    }
    
    func test_load_onExpiredCache_hasNoSideEffects() async {
        let (sut, spy) = makeSUT()
        let moreThanMaxOldTimestamp = cacheMaxAgeLimitTimestamp.adding(seconds: -1)
        let expiredCache = LocalGalleryCache(gallery: uniqueLocalImages().local, timestamp: moreThanMaxOldTimestamp)
        spy.stub(retrivalReturn: expiredCache)
        
        _ = try? await sut.load()
        
        XCTAssertEqual(spy.receivedMessages, [.retrieve])
    }
}

// MARK: - Helpers
private extension LoadGalleryFromCacheUseCaseTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalGalleryLoader, store: GalleryStoreSpy) {
        let store = GalleryStoreSpy()
        let sut = LocalGalleryLoader(store: store)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        
        return (sut, store)
    }
    
    var cacheMaxAgeLimitTimestamp: Date {
        let currentDate = Date()
        return currentDate.adding(days: -2)
    }
}
