//
//  LoadGalleryFromCacheUseCaseTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 15/03/24.
//

import XCTest
import NASAGallery

/* Author Notes on RemoteGalleryLoaderTests
 - Load Galley from Cache Use Case is the LocalStore load command, which will conform to `GalleryLoader` protocol
 - LocalGalleryLoader was also choosen to be the component where this functionality would reside, but this could easily be swapped to a separate space!
    - thus the test_init_doesNotMessageStoreUponCreation appears to be duplicated, but it is not.

 ### Load APOD Gallery from Cache Use Case

 #### Primary course:
 1. Execute "Retrieve Cached APOD Gallery" command.
 2. System fetches APOD Gallery data from cache.
 3. System validates cache age againts maximum age: verify if it is less than 2 days old.
 4. System creates APOD Gallery from valid cached data.
 5. System delivers APOD Gallery.

 #### Error course (sad path):
 1. System delivers no APOD Gallery.

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
    
    func test_load_requestsCacheRetrival() {
        let (sut, spy) = makeSUT()
        
        _ = try? sut.load()
        
        XCTAssertEqual(spy.receivedMessages, [.retrieve])
    }
    
    // MARK: - Error Cases
    
    func test_load_onRetrivalError_fails() {
        let (sut, spy) = makeSUT()
        spy.stub(retrivalError: AnyError(message: "Retrival Error"))
        
        XCTAssertThrowsError(try sut.load())
    }
    
    func test_load_onEmptyCache_failsWithNoImages() throws {
        let (sut, spy) = makeSUT()
        let expectedCache = LocalCache(gallery: [], timestamp: Date())
        spy.stub(retrivalReturn: expectedCache)
        
        let cache = try sut.load()
        
        XCTAssertEqual(cache, expectedCache.gallery)
    }
    
    // MARK: - Validating and Triangulation
    
    // Succeess case
    func test_load_OnLessThanMaxOldAgeCache_succesdsWithCachedImages() throws {
        let (sut, spy) = makeSUT()
        let oneDay = DateComponents(day: -1)
        let previousDay = Calendar.current.date(byAdding: oneDay, to: Date())!
        let expectedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: previousDay)
        spy.stub(retrivalReturn: expectedCache)
        
        let cache = try sut.load()
        
        XCTAssertEqual(cache, expectedCache.gallery)
    }
    
    func test_load_OnMaxOldAgeCache_failsWithEmptyImages() throws {
        let (sut, spy) = makeSUT()
        let oneDay = DateComponents(day: -2)
        let previousDay = Calendar.current.date(byAdding: oneDay, to: Date())!
        let expiredCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: previousDay)
        spy.stub(retrivalReturn: expiredCache)
        
        let cache = try sut.load()
        
        XCTAssertEqual(cache, [])
    }
    
    func test_load_OnMoreThanMaxOldAgeCache_failsWithEmptyImages() throws {
        let (sut, spy) = makeSUT()
        let oneDay = DateComponents(day: -4)
        let previousDay = Calendar.current.date(byAdding: oneDay, to: Date())!
        let expiredCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: previousDay)
        spy.stub(retrivalReturn: expiredCache)
        
        let cache = try sut.load()
        
        XCTAssertEqual(cache, [])
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
}
