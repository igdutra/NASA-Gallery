//
//  SwiftDataGalleryStoreTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 14/11/24.
//

import XCTest
import NASAGallery
import SwiftData

final class SwiftDataGalleryStoreTests: XCTestCase, GalleryStoreSpecs {
    func test_retrieve_onEmptyCache_deliversEmpty() async throws {
        let sut = try makeSUT()
        
        await assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_onNonEmptyCache_succeedsWithCache() async throws {
        let sut = try makeSUT()
        
        await assertThatRetrieveSucceedsWithCacheOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_onEmptyCache_hasNoSideEffects() async throws {
        let sut = try makeSUT()
        
        await assertThatRetrieveHasNoSideEffectOnEmptyCache(on: sut)
    }
    
    func test_retrieve_onNonEmptyCache_hasNoSideEffects() async throws {
        let sut = try makeSUT()
        
        await assertThatRetrieveHasNoSideEffectOnEmptyCache(on: sut)
    }
    
    func test_insert_onEmptyCache_succeedsWithNoThrow() async throws {
        let sut = try makeSUT()
        
        try await assertThatInsertSucceedsOnEmptyCache(on: sut)
    }
    
    func test_insert_onNonEmptyCache_succeedsWithNoThrow() async throws {
        let sut = try makeSUT()
        
        try await assertThatInsertSucceedsOnNonEmptyCache(on: sut)
    }
    
    func test_insert_onNonEmptyCache_succeedsWithOverridingPreviousCache() async throws {
        let sut = try makeSUT()
        
        try await assertThatInsertOverridesPreviousCacheOnNonEmptyCache(on: sut)
    }
    
    func test_delete_onEmptyCache_succeeds() async throws {
        let sut = try makeSUT()
        
        try await assertThatDeleteSucceedsOnEmptyCache(on: sut)
    }
    
    func test_delete_onNonEmptyCache_succeeds() async throws {
        
    }
    
    func test_delete_onEmptyCache_hasNoSideEffects() async throws {
        
    }
    
    func test_delete_onNonEmptyCache_hasNoSideEffects() async throws {
        
    }
}

// MARK: - Helpers

private extension SwiftDataGalleryStoreTests {
    func makeSUT() throws -> SwiftDataGalleryStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SwiftDataStoredGalleryCache.self,
                                           configurations: config)
        
        return SwiftDataGalleryStore(modelContainer: container)
    }
}
