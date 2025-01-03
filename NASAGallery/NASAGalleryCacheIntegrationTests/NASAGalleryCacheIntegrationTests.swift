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
 
 - IN INTEGRATION WE TEST ONLY THE HAPPY PATH. Otherwise, tests will grow exponentially.
 
 - Compare the initialization from Store at the makeSUT() function from `NASAGalleryCacheIntegrationTests` with `SwiftDataGalleryStoreTests`
 
 */

final class NASAGalleryCacheIntegrationTests: XCTestCase {
    
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
