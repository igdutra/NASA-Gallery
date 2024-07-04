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
        let cache = try JSONDecoder().decode(Cache.self, from: data)
        return LocalCache(gallery: cache.localGallery, timestamp: cache.timestamp)
    }
    
    func insert(_ cache: LocalCache) throws {
        guard let storeURL = url,
              !FileManager.default.fileExists(atPath: storeURL.path())
        else { throw Error.insert }
        
        let data = try JSONEncoder().encode(Cache(local: cache))
        try data.write(to: storeURL)
    }
    
    // MARK: - DTOs
    
    public struct Cache: Codable {
        let gallery: [CodableLocalGalleryImage]
        let timestamp: Date
        
        var localGallery: [LocalGalleryImage] {
            return gallery.map { $0.local }
        }
        
        public init(local: LocalCache) {
            self.gallery = local.gallery.map { CodableLocalGalleryImage(local: $0) }
            self.timestamp = local.timestamp
        }
    }

    public struct CodableLocalGalleryImage: Codable {
        let title: String
        let url: URL
        let date: String
        let explanation: String
        let mediaType: String
        
        let copyright: String?
        let hdurl: URL?
        let thumbnailUrl: URL?
        
        public init(local: LocalGalleryImage) {
            self.title = local.title
            self.url = local.url
            self.date = local.date
            self.explanation = local.explanation
            self.mediaType = local.mediaType
            self.copyright = local.copyright
            self.hdurl = local.hdurl
            self.thumbnailUrl = local.thumbnailUrl
        }
        
        var local: LocalGalleryImage {
            LocalGalleryImage(title: title, url: url, date: date, explanation: explanation, mediaType: mediaType, copyright: copyright, hdurl: hdurl, thumbnailUrl: thumbnailUrl)
        }
    }
    
    enum Error: Swift.Error {
        case insert
    }
}

final class CodableFeedStoreTests: XCTestCase {
    
    // MARK: - SetUp & TearDown
    
    override func setUp() async throws {
        try await super.setUp()
        Stub.setupEmptyStoreState()
    }
    
    override func tearDown() async throws {
        Stub.undoStoreSideEffects()
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
        let expectedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        try Stub.add(expectedCache)
        
        let result = try sut.retrieve()
        
        XCTAssertEqual(expectedCache.timestamp, result?.timestamp)
        XCTAssertEqual(expectedCache.gallery, result?.gallery)
    }
    
    func test_insert_onEmptyCache_succeeds() throws {
        let sut = makeSUT()
        let insertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())

        XCTAssertNoThrow(try sut.insert(insertedCache))
        
        let retrievedCache = try sut.retrieve()
        XCTAssertEqual(insertedCache, retrievedCache)
    }
}

// MARK: - Helpers

private extension CodableFeedStoreTests {
    func makeSUT() -> CodableGalleryStore {
        let sut = CodableGalleryStore(url: Self.testSpecificURL())
        trackForMemoryLeaks(sut)
        return sut
    }
    
    static func testSpecificURL() -> URL {
        // Note: I thought about returning optinal, but in test using ! to places that you know it's safe, is better!
        FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    enum Stub {
        // TODO: FIX THAT with helpers to get the DTOs
        static func add(_ cache: LocalCache) throws {
            let jsonData = try JSONEncoder().encode(CodableGalleryStore.Cache(local: cache))
            try jsonData.write(to: CodableFeedStoreTests.testSpecificURL())
        }
        
        static func setupEmptyStoreState() {
            clearTestArtifacts()
        }

        static func undoStoreSideEffects() {
            clearTestArtifacts()
        }
        
        private static func clearTestArtifacts() {
            try? FileManager.default.removeItem(at: CodableFeedStoreTests.testSpecificURL())
        }
    }
}
