//
//  GalleryStoreSpecs.swift
//  NASAGalleryTests
//
//  Created by Ivo on 08/08/24.
//

import XCTest

typealias FailableGalleryStoreSpecs = FailableRetrieveGalleryStoreSpecs & FailableInsertGalleryStoreSpecs & FailableDeleteGalleryStoreSpecs
 
protocol GalleryStoreSpecs: XCTestCase {
    // MARK: Retrieve
    func test_retrieve_onEmptyCache_deliversEmpty() async throws
    func test_retrieve_onNonEmptyCache_succeedsWithCache() async throws
    func test_retrieve_onEmptyCache_hasNoSideEffects() async throws
    func test_retrieve_onNonEmptyCache_hasNoSideEffects() async throws
    
    // MARK: Insert
    // NOTE: ah! why insert is the only one that has no test that will assert the side-effects? Cause the insertion is the side-effect.
    // No side-effect should be tested on failure.
    func test_insert_onEmptyCache_succeedsWithNoThrow() async throws
    func test_insert_onNonEmptyCache_succeedsWithNoThrow() async throws
    func test_insert_onNonEmptyCache_succeedsWithOverridingPreviousCache() async throws

    // MARK: Delete
    func test_delete_onEmptyCache_succeeds() async throws
    func test_delete_onNonEmptyCache_succeeds() async throws
    func test_delete_onEmptyCache_hasNoSideEffects() async throws
    func test_delete_onNonEmptyCache_hasNoSideEffects() async throws

//    func test_databaseOperationsOccurSerially() async
}

protocol FailableRetrieveGalleryStoreSpecs: GalleryStoreSpecs {
    func test_retrieve_onRetrivalError_fails() async throws
    func test_retrieve_onRetrivalError_hasNoSideEffects() async throws
}

protocol FailableInsertGalleryStoreSpecs: GalleryStoreSpecs {
    func test_insert_onInsertionError_fails() async throws
    func test_insert_onInsertionError_hasNoSideEffects() async throws
}

protocol FailableDeleteGalleryStoreSpecs: GalleryStoreSpecs {
    func test_delete_onDeletionError_fails() async throws
    func test_delete_onDeletionError_hasNoSideEffects() async throws
}
