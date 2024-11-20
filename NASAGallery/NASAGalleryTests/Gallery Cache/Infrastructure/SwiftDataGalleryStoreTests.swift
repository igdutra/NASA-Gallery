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
    

//    func test() async throws {
//        let sut = try makeSUT()
//        let newUser = User(name: "John Doe")
//        try await sut.insert(user: newUser)
//
//        let results = try await sut.fetchAllUsers()
//        XCTAssertFalse(results.isEmpty)
//        
//        try await sut.delete(user: newUser)
//        let results2 = try await sut.fetchAllUsers()
//        XCTAssertTrue(results2.isEmpty)
//    }
//    
//    func test2_assertThatThereAreNoSideEffects() async throws {
//        let sut = try makeSUT()
//        let newUser = User(name: "John Doe 2")
//        try await sut.insert(user: newUser)
//
//        let results = try await sut.fetchAllUsers()
//        XCTAssertTrue(results.contains(newUser))
//        XCTAssertEqual(results.count, 1)
//    }
}

// MARK: - Helpers

private extension SwiftDataGalleryStoreTests {
    func makeSUT() throws -> SwiftDataGalleryStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SwiftDataStoredGalleryCache.self,
                                           configurations: config)
        
        // Initialize the UserModelActor
        return SwiftDataGalleryStore(modelContainer: container)
    }
}
