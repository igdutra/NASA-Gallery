//
//  NASAGalleryCacheIntegrationTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 03/01/25.
//

import XCTest
import NASAGallery
import SwiftData

/* Author Notes
 
 - Compare the initialization from Store at the makeSUT() function from `NASAGalleryCacheIntegrationTests` with `SwiftDataGalleryStoreTests`
 
 */

final class NASAGalleryCacheIntegrationTests: XCTestCase {
    func test_load_deliversNoItemsOnEmptyCache() async throws {
        let sut = try makeSUT()
        
        let cache = try await sut.load()
        
        XCTAssertEqual(cache, [])
    }
}

// MARK: - Helpers

private extension NASAGalleryCacheIntegrationTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) throws -> LocalGalleryLoader {
        let store = try makeTestSpecificStore()
        let sut = LocalGalleryLoader(store: store)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        
        return sut
    }
    
    func makeTestSpecificStore() throws -> SwiftDataGalleryStore {
        let config = ModelConfiguration(url: testSpecificStoreURL())
        let container = try ModelContainer(for: SwiftDataStoredGalleryCache.self,
                                           configurations: config)
        
        return SwiftDataGalleryStore(modelContainer: container)
    }
    
    func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
