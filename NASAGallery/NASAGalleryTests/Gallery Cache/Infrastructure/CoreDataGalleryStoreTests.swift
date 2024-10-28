//
//  CoreDataGalleryStore.swift
//  NASAGalleryTests
//
//  Created by Ivo on 01/10/24.
//

import XCTest
import NASAGallery

/* Author notes on CoreDataGalleryStoreTests
 
 Per Caio's comment:
 it’s not straightforward to force erros in Core Data.
 It requires techniques like swizzling, which are not ideal.
 And the risk is very low here because it should just complete with the error without any behavior.
 So we decided it was best not to test the error cases since it’s not possible without not ideal solutions.
 
 Implementing the failable tests once the entire normal feedspec suit is done!
 
 */

final class CoreDataGalleryStoreTests: XCTestCase, FailableGalleryStoreSpecs {
    
    // MARK: - Retrieve
    

    func test_retrieve_onEmptyCache_deliversEmpty() async throws {
        let sut = try makeSUT()
        
        await assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_onEmptyCache_hasNoSideEffects() async throws {
        let sut = try makeSUT()
        
        await assertThatRetrieveHasNoSideEffectOnEmptyCache(on: sut)
    }
    
    func test_retrieve_onNonEmptyCache_succeedsWithCache() async throws {
        let sut = try makeSUT()
        
        await assertThatRetrieveSucceedsWithCacheOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_onNonEmptyCache_hasNoSideEffects() async throws {
        let sut = try makeSUT()
        
        await assertThatRetrieveHasNoSideEffectOnNonEmptyCache(on: sut)
    }
    
    // MARK: - Insert
    
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
    
    // MARK: - Delete

    func test_delete_onEmptyCache_succeeds() async throws {
        
    }
    
    func test_delete_onEmptyCache_hasNoSideEffects() async throws {
        
    }
    
    func test_delete_onNonEmptyCache_succeeds() async throws {
        
    }
    
    func test_delete_onNonEmptyCache_hasNoSideEffects() async throws {
        
    }
    
    // MARK: - Failable tests - Swizzling
    
    func test_retrieve_onRetrivalError_fails() async throws {
    
    }
    
    func test_retrieve_onRetrivalError_hasNoSideEffects() async throws {
    
    }
    
    func test_insert_onInsertionError_fails() async throws {
        
    }
    
    func test_insert_onInsertionError_hasNoSideEffects() async throws {
        
    }
    
    func test_delete_onDeletionError_fails() async throws {
        
    }
    
    func test_delete_onDeletionError_hasNoSideEffects() async throws {
        
    }
}

// MARK: - Helpers

private extension CoreDataGalleryStoreTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) throws -> GalleryStore {
        let storeBundle = Bundle(for: CoreDataGalleryStore.self)
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try CoreDataGalleryStore(storeBundle: storeBundle, storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
