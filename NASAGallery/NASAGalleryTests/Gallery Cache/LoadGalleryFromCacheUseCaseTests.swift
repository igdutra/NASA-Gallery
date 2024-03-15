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
 1. Execute "Load Cached APOD Gallery" command with the maximum cache age parameter - two days.
 2. System fetches APOD Gallery data from cache.
 3. System validates cache age is less than 2 days.
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
}

// MARK: - Helpers
private extension LoadGalleryFromCacheUseCaseTests {
    func makeSUT() -> (sut: LocalGalleryLoader, store: GalleryStoreSpy) {
        let store = GalleryStoreSpy()
        let sut = LocalGalleryLoader(store: store)
        
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(store)
        
        return (sut, store)
    }
}
