//
//  CodableGalleryStoreTests.swift
//  NASAGallery
//
//  Created by Ivo on 27/06/24.
//

import XCTest
import NASAGallery

/* Author Notes on CodableGalleryStore
 Codable implementation of the GalleryStore
 
 - This is not a use case to follow certain patters, but it is importatant to write a series of expectations, to help drive the unit tests!
 - Initially the DTOs were made public, so we could stub upfront the behavior and assuring that the cache would be non-nil so we can then test the retrival method. THIS IS NOT what we want (when testing only through public interfaces) because the DTOs have no reason to be made public! Thus we would be turing something public only so we could test it, and that is not desired for this project. Solution: test retrieve + insert in conjunction
 
## `GalleryStore` implementation Inbox

- Retrieve
    ✅ Empty cache returns empty
    ✅ Empty cache twice returns empty (no side-effects) (added in this lecture to be sure of side effects)
    ✅ Non-empty cache returns data
    ✅ Non-empty cache twice returns same data (no side-effects)
    ✅ Error returns error (if applicable, e.g., invalid data)
    ✅ Error twice returns same error (if applicable, e.g., invalid data)
- Insert
    ✅ To empty cache stores data
    ✅ To non-empty cache overrides previous data with new data
    ✅ Error (if applicable, e.g., no write permission)
- Delete
    ✅ Empty cache does nothing (cache stays empty and does not fail)
    ✅ Non-empty cache leaves cache empty
    ✅ Error (if applicable, e.g., no delete permission)
- Side-effects must run serially to avoid race-conditions

*/

/* On GalleryStoreSpecs
 
 The Infrastructure Specs where retrieved as an exercise, in a way that the names for CodableGalleryStore were not updated.
 
 */

final class CodableGalleryStoreTests: XCTestCase, FailableGalleryStoreSpecs {
    
    // MARK: - SetUp & TearDown
    
    override func setUp() async throws {
        try await super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() async throws {
        undoStoreSideEffects()
        try await super.tearDown()
    }
    
    // MARK: Retrieve
    
    func test_retrieve_onEmptyCache_deliversEmpty() async {
        // Note: since we are testing the real infra, the folder must be empty, so no stub is needed.
        let sut = makeSUT()
        
        await assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_onNonEmptyCache_succeedsWithCache() async {
        let sut = makeSUT()

        await assertThatRetrieveSucceedsWithCacheOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_onEmptyCache_hasNoSideEffects() async {
        // Note: since we are testing the real infra, the folder must be empty does no stub is needed.
        let sut = makeSUT()
        
        await assertThatRetrieveHasNoSideEffectOnEmptyCache(on: sut)
    }
    
    func test_retrieve_onNonEmptyCache_hasNoSideEffects() async {
        let sut = makeSUT()
       
        await assertThatRetrieveHasNoSideEffectOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_onRetrivalError_fails() async {
        let storeURL = testSpecificURL()
        let sut = makeSUT(storeURL: storeURL)
        stubInvalidData(in: storeURL)
        
        await assertThatRetrieveFailsOnRetrivalError(on: sut)
    }
    
    func test_retrieve_onRetrivalError_hasNoSideEffects() async {
        let storeURL = testSpecificURL()
        let sut = makeSUT(storeURL: storeURL)
        stubInvalidData(in: storeURL)
        
        await assertThatRetrieveHasNoSideEffectOnRetrivalError(on: sut)
    }
    
    // MARK: Insert
    
    func test_insert_onEmptyCache_succeedsWithNoThrow() async throws {
        let sut = makeSUT()

        try await assertThatInsertSucceedsOnEmptyCache(on: sut)
    }
    
    func test_insert_onNonEmptyCache_succeedsWithNoThrow() async throws {
        let sut = makeSUT()
        
       try await assertThatInsertSucceedsOnNonEmptyCache(on: sut)
    }
    
    func test_insert_onNonEmptyCache_succeedsWithOverridingPreviousCache() async throws {
        let sut = makeSUT()
 
        try await assertThatInsertOverridesPreviousCacheOnNonEmptyCache(on: sut)
    }
    
    func test_insert_onInsertionError_fails() async {
        let noWritePermissionDirectory = cachesDirectory()
        let sut = makeSUT(storeURL: noWritePermissionDirectory)
       
        await assertThatInsertFailsOnInsertionError(on: sut)
    }
    
    func test_insert_onInsertionError_hasNoSideEffects() async throws {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        
        await assertThatInsertHasNoSideEffectOnInsertionError(on: sut)
    }
    
    // MARK: Delete
    
    func test_delete_onEmptyCache_succeeds() async throws {
        let sut = makeSUT()
        
       try await assertThatDeleteSucceedsOnEmptyCache(on: sut)
    }
    
    func test_delete_onEmptyCache_hasNoSideEffects() async throws {
        let sut = makeSUT()
        
       try await assertThatDeleteHasNoSideEffectOnEmptyCache(on: sut)
    }
    
    // Note: previous test, test_delete_onNonEmptyCache_succeedsClearingCache, was broken down into 2 separte assertions. One test will assert it succeeds, the other will assert that it leaves no side effects.
    func test_delete_onNonEmptyCache_succeeds() async throws {
        let sut = makeSUT()
        
        try await assertThatDeleteSucceedsOnNonEmptyCache(on: sut)
    }
    
    func test_delete_onNonEmptyCache_hasNoSideEffects() async throws {
        let sut = makeSUT()
        
        try await assertThatDeleteHasNoSideEffectOnNonEmptyCache(on: sut)
    }
    
    func test_delete_onDeletionError_fails() async {
        let noWritePermissionDirectory = cachesDirectory()
        let sut = makeSUT(storeURL: noWritePermissionDirectory)
        
        await assertThatDeleteFailsOnDeletionError(on: sut)
    }
    
    func test_delete_onDeletionError_hasNoSideEffects() async {
        let noWritePermissionDirectory = cachesDirectory()
        let sut = makeSUT(storeURL: noWritePermissionDirectory)
        
        await assertThatDeleteHasNoSideEffectOnDeletionError(on: sut,
                                                             testDirectory: noWritePermissionDirectory)
    }
    
    // MARK: - Serially
    
    // Note: Serially
    // - this test is here testing the swift language itself
    // - just to demonstrate how the language guarantees that the operations, though async, will occur one after the other.
    // Why this is here? Previously there was a test to guarnatee that, using DispatchQueues, these operations would run serially.
     func test_databaseOperationsOccurSerially() async {
         let sut = makeSUT()
         let insertedCache1 = LocalGalleryCache(gallery: uniqueLocalImages().local, timestamp: Date())
         let insertedCache2 = LocalGalleryCache(gallery: uniqueLocalImages().local, timestamp: Date())
         let insertedCache3 = LocalGalleryCache(gallery: uniqueLocalImages().local, timestamp: Date())
         var results: [LocalGalleryCache?] = []
         
         try? await sut.insert(insertedCache1)
         await results.append(try? sut.retrieve())
         try? await sut.insert(insertedCache2)
         await results.append(try? sut.retrieve())
         try? await sut.insert(insertedCache3)
         await results.append(try? sut.retrieve())
         
         XCTAssertEqual(results, [insertedCache1, insertedCache2, insertedCache3])
     }
}

// MARK: - Helpers

private extension CodableGalleryStoreTests {
    func makeSUT(storeURL: URL? = nil) -> GalleryStore {
        let sut = CodableGalleryStore(storeURL: storeURL ?? testSpecificURL())
        trackForMemoryLeaks(sut)
        return sut
    }
    
    func stubInvalidData(in url: URL) {
        try! "invalid data".write(to: url, atomically: false, encoding: .utf8)
    }
    
    func testSpecificURL() -> URL {
        // Note: I thought about returning optinal, but in test using ! to places that you know it's safe, is better!
        FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    func cachesDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first!
    }
    
    func cachesDirectoryFile() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    func setupEmptyStoreState() {
        clearTestArtifacts()
    }

    func undoStoreSideEffects() {
        clearTestArtifacts()
    }
    
    func clearTestArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificURL())
    }
}
