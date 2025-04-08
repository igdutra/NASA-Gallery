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
 
 - Due to the power of the LSP, ISP and others, simply replace in the makeSUT func the store for the other infrastructure implementations, and tests will pass.
 
 RESULTS:
 - with SwiftData:
 Test Suite 'NASAGalleryCacheIntegrationTests' passed at 2025-01-03 10:18:20.047.
      Executed 3 tests, with 0 failures (0 unexpected) in 0.049 (0.050) seconds
 
 - with FileManager:
 Test Suite 'NASAGalleryCacheIntegrationTests' passed at 2025-01-03 10:18:52.599.
      Executed 3 tests, with 0 failures (0 unexpected) in 0.009 (0.010) seconds
 
 - with CoreData:
 Test Suite 'NASAGalleryCacheIntegrationTests' passed at 2025-01-03 10:20:00.526.
      Executed 3 tests, with 0 failures (0 unexpected) in 0.062 (0.063) seconds
 
PRETTY COOL!
 
 - IN INTEGRATION WE TEST ONLY THE HAPPY PATH. Otherwise, tests will grow exponentially.
 
 - Compare the initialization from Store at the makeSUT() function from `NASAGalleryCacheIntegrationTests` with `SwiftDataGalleryStoreTests`
 */

final class _NASAGalleryCacheIntegrationTests: XCTestCase {
    
    // MARK: - SetUp & TearDown
    
    override func setUp() async throws {
        try await super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() async throws {
        undoStoreSideEffects()
        try await super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_load_onEmptyCache_succeeds() async throws {
        let sut = try makeSUT()
        
        let cache = try await sut.load()
        
        XCTAssertEqual(cache, [])
    }
    
    func test_load_itemsSavedOnASeparateInstance_succeeds() async throws {
        let sutToPerformSave = try makeSUT()
        let sutToPerformLoad = try makeSUT()
        let expectedGallery = uniqueLocalImages().images
        
        try await sutToPerformSave.save(gallery:expectedGallery, timestamp: Date())
        
        let result = try await sutToPerformLoad.load()
        
        XCTAssertEqual(result, expectedGallery)
    }
    
    func test_save_overridingItemsSavedOnASeparateInstance_succeeds() async throws {
        let sutToPerformFirstSave = try makeSUT()
        let sutToPerformSecondSave = try makeSUT()
        let sutToPerformLoad = try makeSUT()
        let firstSavedGallery = uniqueLocalImages().images
        let secondSavedGallery = uniqueLocalImages(title: "This is a second gallery").images

        try await sutToPerformFirstSave.save(gallery: firstSavedGallery, timestamp: Date())
        
        try await sutToPerformSecondSave.save(gallery: secondSavedGallery, timestamp: Date())
        
        let result = try await sutToPerformLoad.load()
        
        XCTAssertEqual(result, secondSavedGallery)
    }
}

// MARK: - Helpers

private extension _NASAGalleryCacheIntegrationTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) throws -> LocalGalleryLoader {
        let store = try makeSwiftDataTestSpecificStore()
        // Note: we are able to simply swap the store implementation, and tests will pass (LSP principle).
//        let store = CodableGalleryStore(storeURL: testSpecificStoreURL())
//        let store = try makeCoreDataTestSpecificStore()
        let sut = LocalGalleryLoader(store: store)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        
        return sut
    }
    
    func makeSwiftDataTestSpecificStore() throws -> SwiftDataGalleryStore {
        let config = ModelConfiguration(url: testSpecificStoreURL())
        let container = try ModelContainer(for: SwiftDataStoredGalleryCache.self,
                                           configurations: config)
        
        return SwiftDataGalleryStore(modelContainer: container)
    }
    
    func makeCoreDataTestSpecificStore() throws -> CoreDataGalleryStore {
        let storeBundle = Bundle(for: CoreDataGalleryStore.self)
        return try CoreDataGalleryStore(storeBundle: storeBundle, storeURL: testSpecificStoreURL())
    }
    
    func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    // MARK: Undo side-effects
    
    func setupEmptyStoreState() {
        clearStoreArtifacts()
    }

    func undoStoreSideEffects() {
        clearStoreArtifacts()
    }
    
    func clearStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
