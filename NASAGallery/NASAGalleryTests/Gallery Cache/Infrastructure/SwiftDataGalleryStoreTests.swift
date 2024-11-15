//
//  SwiftDataGalleryStoreTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 14/11/24.
//

import XCTest
import NASAGallery
import SwiftData

final class SwiftDataGalleryStoreTests: XCTestCase {

    func test() async throws {
        let sut = try makeSUT()
        let newUser = User(name: "John Doe")
        try await sut.insert(user: newUser)

        let results = try await sut.fetchAllUsers()
        XCTAssertFalse(results.isEmpty)
        
        try await sut.delete(user: newUser)
        let results2 = try await sut.fetchAllUsers()
        XCTAssertTrue(results2.isEmpty)
    }
    
    func test2_assertThatThereAreNoSideEffects() async throws {
        let sut = try makeSUT()
        let newUser = User(name: "John Doe 2")
        try await sut.insert(user: newUser)

        let results = try await sut.fetchAllUsers()
        XCTAssertTrue(results.contains(newUser))
        XCTAssertEqual(results.count, 1)
    }
}

// MARK: - Helpers

private extension SwiftDataGalleryStoreTests {
    func makeSUT() throws -> UserModelActor {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: User.self, configurations: config)
        
        // Initialize the UserModelActor
        return UserModelActor(modelContainer: container)
    }
}
