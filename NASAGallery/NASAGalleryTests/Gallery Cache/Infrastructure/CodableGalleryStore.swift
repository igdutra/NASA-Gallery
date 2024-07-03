//
//  CodableGalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 27/06/24.
//

import XCTest
import NASAGallery

/* Author Notes on CodableGalleryStore
 Codable implementation of the GalleryStore
 
 This is not a use case to follow certain patters, but it is importatant to write a series of expectations, to help drive the unit tests!
 
## `GalleryStore` implementation Inbox

- Retrieve
    ✅ Empty cache returns empty
    ✅ Empty cache twice returns empty (no side-effects) (added in this lecture to be sure of side effects)
    ✅ Non-empty cache returns data
    - Non-empty cache twice returns same data (no side-effects)
    - Error returns error (if applicable, e.g., invalid data)
    - Error twice returns same error (if applicable, e.g., invalid data)
- Insert
    ✅ To empty cache stores data
    - To non-empty cache overrides previous data with new data
    - Error (if applicable, e.g., no write permission)
- Delete
    - Empty cache does nothing (cache stays empty and does not fail)
    - Non-empty cache leaves cache empty
    - Error (if applicable, e.g., no delete permission)
- Side-effects must run serially to avoid race-conditions

*/

final class CodableGalleryStore {
    let url: URL?
    
    init(url: URL?) {
        self.url = url
    }
    
    func retrieve() throws -> LocalCache? {
        guard let storeURL = url,
              FileManager.default.fileExists(atPath: storeURL.path())
        else { return nil }
        
        let data = try Data(contentsOf: storeURL)
        let jsonData = try JSONDecoder().decode(LocalCache.self, from: data)
        return jsonData
    }
}

final class CodableFeedStoreTests: XCTestCase {
    
    // MARK: - SetUp & TearDown
    
    override func setUp() async throws {
        try await super.setUp()
        Stub.clearTestArtifacts()
    }
    
    override func tearDown() async throws {
        Stub.clearTestArtifacts()
        try await super.tearDown()
    }
    
    // MARK: - Test Methods
    
    func test_retrieve_onEmptyCache_deliversEmpty() throws {
        // Note: since we are testing the real infra, the folder must be empty does no stub is needed.
        let sut = makeSUT()
        
        let result = try sut.retrieve()
        
        XCTAssertNil(result)
    }
    
    func test_retrieveTwice_onEmptyCache_hasNoSideEffects() throws {
        // Note: since we are testing the real infra, the folder must be empty does no stub is needed.
        let sut = makeSUT()
        
        let result = try sut.retrieve()
        let result2 = try sut.retrieve()
        
        XCTAssertNil(result)
        XCTAssertNil(result2)
    }
    
    func test_retrieve_onNonEmptyCache_succeedsWithCache() throws {
        let sut = makeSUT()
        // TODO: move that to a helper
        let lessThanMaxOldTimestamp = cacheMaxAgeLimitTimestamp.adding(seconds: 1)
        let expectedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: lessThanMaxOldTimestamp)
        try Stub.add(expectedCache)
        
        let result = try sut.retrieve()
        
        XCTAssertEqual(expectedCache.timestamp, result?.timestamp)
        XCTAssertEqual(expectedCache.gallery, result?.gallery)
    }
}

// MARK: - Helpers

private extension CodableFeedStoreTests {
    func makeSUT() -> CodableGalleryStore {
        CodableGalleryStore(url: Self.testSpecificURL())
    }
    
    static func testSpecificURL() -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first?.appending(path: String(describing: self))
    }
    
    enum Stub {
        static func add(_ cache: LocalCache) throws {
            guard let url = CodableFeedStoreTests.testSpecificURL() else { throw AnyError(message: "Failed to get test URL") }
            let jsonData = try JSONEncoder().encode(cache)
            try jsonData.write(to: url)
        }
        
        static func clearTestArtifacts() {
            guard let url = CodableFeedStoreTests.testSpecificURL() else { return }
            try? FileManager.default.removeItem(at: url)
        }
    }
}
