//
//  CoreDataGalleryStore.swift
//  NASAGalleryTests
//
//  Created by Ivo on 01/10/24.
//

import XCTest

final class CoreDataGalleryStore: XCTestCase, FailableGalleryStoreSpecs {
    
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
    
    func test_retrieve_onEmptyCache_deliversEmpty() async throws {
        
    }
    
    func test_retrieve_onNonEmptyCache_succeedsWithCache() async throws {
        
    }
    
    func test_retrieve_onEmptyCache_hasNoSideEffects() async throws {
        
    }
    
    func test_retrieve_onNonEmptyCache_hasNoSideEffects() async throws {
        
    }
    
    func test_insert_onEmptyCache_succeedsWithNoThrow() async throws {
        
    }
    
    func test_insert_onNonEmptyCache_succeedsWithNoThrow() async throws {
        
    }
    
    func test_insert_onNonEmptyCache_succeedsWithOverridingPreviousCache() async throws {
        
    }
    
    func test_delete_onEmptyCache_succeeds() async throws {
        
    }
    
    func test_delete_onNonEmptyCache_succeeds() async throws {
        
    }
    
    func test_delete_onEmptyCache_hasNoSideEffects() async throws {
        
    }
    
    func test_delete_onNonEmptyCache_hasNoSideEffects() async throws {
        
    }
}
