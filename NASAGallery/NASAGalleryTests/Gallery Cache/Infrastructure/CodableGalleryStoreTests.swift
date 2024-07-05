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

final class CodableGalleryStore: GalleryStore {
    let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func retrieve() throws -> LocalCache? {
        guard FileManager.default.fileExists(atPath: storeURL.path()) else { return nil }
        
        let data = try Data(contentsOf: storeURL)
        let cache = try JSONDecoder().decode(Cache.self, from: data)
        return LocalCache(gallery: cache.localGallery, timestamp: cache.timestamp)
    }
    
    func insert(_ cache: LocalCache) throws {
        let codableCache = Cache(gallery: cache.gallery.map(CodableLocalGalleryImage.init), timestamp: cache.timestamp)
        let data = try JSONEncoder().encode(codableCache)
        try data.write(to: storeURL)
    }
    
    func deleteCachedGallery() throws {
        guard FileManager.default.fileExists(atPath: storeURL.path()) else { return }
        try FileManager.default.removeItem(at: storeURL)
    }
    
    // MARK: - DTOs
    
    private struct Cache: Codable {
        let gallery: [CodableLocalGalleryImage]
        let timestamp: Date
        
        var localGallery: [LocalGalleryImage] {
            return gallery.map { $0.local }
        }
    }

    private struct CodableLocalGalleryImage: Codable {
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
}

final class CodableGalleryStoreTests: XCTestCase {
    
    // MARK: - SetUp & TearDown
    
    override func setUp() async throws {
        try await super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() async throws {
        undoStoreSideEffects()
        try await super.tearDown()
    }
    
    // MARK: - Test Methods
    
    // MARK: Retrieve
    
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
    
    func test_retrieve_onInvalidData_fails() {
        let storeURL = testSpecificURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        XCTAssertThrowsError(try sut.retrieve(), "Retrieve should fail due to invalid data")
    }
    
    func test_retrieveTwice_onInvalidData_failsTwiceWithSameError() {
        let storeURL = testSpecificURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: testSpecificURL(), atomically: false, encoding: .utf8)
        
        var firstError: NSError?
        var secondError: NSError?
        
        do {
            _ = try sut.retrieve()
            XCTFail("Retrieve should fail due to invalid data")
        } catch let error as NSError {
            firstError = error
        }
        
        do {
            _ = try sut.retrieve()
            XCTFail("Retrieve should fail due to invalid data")
        } catch let error as NSError {
            secondError = error
        }
        
        XCTAssertEqual(firstError, secondError)
    }
    
    // MARK: Insert
    
    func test_retrieve_afterInserting_succeedsWithCache() throws {
        let sut = makeSUT()
        let expectedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
 
        try sut.insert(expectedCache)
        let result = try sut.retrieve()
        
        XCTAssertEqual(expectedCache.timestamp, result?.timestamp)
        XCTAssertEqual(expectedCache.gallery, result?.gallery)
    }
    
    func test_insert_onEmptyCache_succeedsWithNoThrow() {
        let sut = makeSUT()
        let insertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())

        XCTAssertNoThrow(try sut.insert(insertedCache))
    }
    
    func test_insert_onNonEmptyCache_succeedsWithOverridingPreviousCache() throws {
        let sut = makeSUT()
        let previousInsertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        
        XCTAssertNoThrow(try sut.insert(previousInsertedCache))
        
        let lastInsertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        
        XCTAssertNoThrow(try sut.insert(lastInsertedCache))

        let retrievedCache = try sut.retrieve()
        
        XCTAssertEqual(retrievedCache, lastInsertedCache)
    }
    
    func test_insert_onInsertionError_fails() {
        let noWritePermissionDirectory = cachesDirectory()
        let sut = makeSUT(storeURL: noWritePermissionDirectory)
        let insertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        
        XCTAssertThrowsError(try sut.insert(insertedCache), "Insert should fail on no-write permission directory")
    }
    
    // MARK: Delete
    
    func test_delete_onEmptyCache_succeeds() {
        let sut = makeSUT()
        
        XCTAssertNoThrow(try sut.deleteCachedGallery())
    }
    
    func test_delete_onNonEmptyCache_succeedsClearingCache() throws {
        let sut = makeSUT()
        let insertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        try sut.insert(insertedCache)
        
        try sut.deleteCachedGallery()
        
        let result = try sut.retrieve()
        XCTAssertNil(result, "Cache should be empty after deletion")
    }
    
    func test_delete_onDeletionError_fails() {
        let noWritePermissionDirectory = cachesDirectory()
        let sut = makeSUT(storeURL: noWritePermissionDirectory)
        
        XCTAssertThrowsError(try sut.deleteCachedGallery(), "Delete should fail on no-write permission directory")
    }
}

// MARK: - Helpers

private extension CodableGalleryStoreTests {
    func makeSUT(storeURL: URL? = nil) -> GalleryStore {
        let sut = CodableGalleryStore(storeURL: storeURL ?? testSpecificURL())
        trackForMemoryLeaks(sut)
        return sut
    }
    
    func testSpecificURL() -> URL {
        // Note: I thought about returning optinal, but in test using ! to places that you know it's safe, is better!
        FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    func cachesDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!
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
