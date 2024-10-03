//
//  CoreDataGalleryStore.swift
//  NASAGalleryTests
//
//  Created by Ivo on 01/10/24.
//

import XCTest
import NASAGallery


// TODO: add this optimization  // Verify that the context has uncommitted changes.
//guard persistentContainer.viewContext.hasChanges else { return }

final class CoreDataGalleryStore: GalleryStore {
    func delete() async throws {
        
    }
    
    func insert(_ cache: LocalCache) async throws {
        
    }
    
    func retrieve() async throws -> LocalCache? {
        return nil
    }
}

final class CoreDataGalleryStoreTests: XCTestCase, FailableGalleryStoreSpecs {
    
    // MARK: - Retrieve
    

    func test_retrieve_onEmptyCache_deliversEmpty() async throws {
        let sut = makeSUT()
        
        await assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_onEmptyCache_hasNoSideEffects() async throws {
        
    }
    
    func test_retrieve_onNonEmptyCache_hasNoSideEffects() async throws {
        
    }
    
    func test_retrieve_onNonEmptyCache_succeedsWithCache() async throws {
        
    }
    
    func test_retrieve_onRetrivalError_fails() async throws {
    
    }
    
    func test_retrieve_onRetrivalError_hasNoSideEffects() async throws {
    
    }
    
    // MARK: - Insert
    
    func test_insert_onEmptyCache_succeedsWithNoThrow() async throws {
        
    }
    
    func test_insert_onNonEmptyCache_succeedsWithNoThrow() async throws {
        
    }
    
    func test_insert_onNonEmptyCache_succeedsWithOverridingPreviousCache() async throws {
        
    }
    
    func test_insert_onInsertionError_fails() async throws {
        
    }
    
    func test_insert_onInsertionError_hasNoSideEffects() async throws {
        
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
    
    func test_delete_onDeletionError_fails() async throws {
        
    }
    
    func test_delete_onDeletionError_hasNoSideEffects() async throws {
        
    }
}

// MARK: - Helpers

private extension CoreDataGalleryStoreTests {
    func makeSUT() -> GalleryStore {
        let store = CoreDataGalleryStore()
        trackForMemoryLeaks(store)
        return store
    }
}
