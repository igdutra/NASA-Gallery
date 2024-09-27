//
//  GalleryStoreSpecs+Assertions.swift
//  NASAGalleryTests
//
//  Created by Ivo on 27/09/24.
//

import XCTest
import NASAGallery

// MARK: - Retrieve

extension GalleryStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: GalleryStore,
                                                     file: StaticString = #file, line: UInt = #line) async {
        await expect(sut,
                     toRetrieve: nil,
                     "Result should be empty on empty cache",
                     file: file, line: line)
    }
    
    func assertThatRetrieveSucceedsWithCacheOnNonEmptyCache(on sut: GalleryStore,
                                                            file: StaticString = #file, line: UInt = #line) async {
        let expectedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
 
        await insert(expectedCache, to: sut, file: file, line: line)
        
        await expect(sut,
                     toRetrieve: expectedCache,
                     "Retrieve should work on non-empty cache",
                     file: file, line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectOnEmptyCache(on sut: GalleryStore,
                                                       file: StaticString = #file, line: UInt = #line) async {
        await expect(sut,
                     toRetrieveTwice: nil,
                     "Retrieve should have no sideEffect on empty cache",
                     file: file, line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectOnNonEmptyCache(on sut: GalleryStore,
                                                          file: StaticString = #file, line: UInt = #line) async {
        let expectedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        await insert(expectedCache, to: sut, file: file, line: line)

        await expect(sut,
                     toRetrieveTwice: expectedCache,
                     "Retrieve should have no sideEffect on NON-empty cache",
                     file: file, line: line)
    }
}

// MARK: - Failable Retrieve

extension FailableRetrieveGalleryStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveFailsOnRetrivalError(on sut: GalleryStore,
                                                file: StaticString = #file, line: UInt = #line) async {
        await expectThrowAsync(try await sut.retrieve(),
                               "Retrieve should fail due to invalid data",
                               file: file, line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectOnRetrivalError(on sut: GalleryStore,
                                                          file: StaticString = #file, line: UInt = #line) async {
        let firstError = await expectThrowAsync(try await sut.retrieve(), file: file, line: line)
        let secondError = await expectThrowAsync(try await sut.retrieve(), file: file, line: line)
        
        XCTAssertEqual(firstError?.localizedDescription, secondError?.localizedDescription, file: file, line: line)
    }
}

// MARK: - Insert

extension GalleryStoreSpecs where Self: XCTestCase {
    func assertThatInsertSucceedsOnEmptyCache(on sut: GalleryStore,
                                              file: StaticString = #file, line: UInt = #line) async throws {
        let insertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        
        try await expectNoThrowAsync(try await sut.insert(insertedCache),
                                     "Insertion should succeed",
                                     file: file, line: line)
    }
    
    func assertThatInsertSucceedsOnNonEmptyCache(on sut: GalleryStore,
                                                 file: StaticString = #file, line: UInt = #line) async throws {
        let firstInsertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        await insert(firstInsertedCache, to: sut)
        
        let secondInsertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        try await expectNoThrowAsync(try await sut.insert(secondInsertedCache),
                                     "Both insertions should succeed with no throw",
                                     file: file, line: line)
    }
    
    func assertThatInsertOverridesPreviousCacheOnNonEmptyCache(on sut: GalleryStore,
                                                               file: StaticString = #file, line: UInt = #line) async throws {
        let previousInsertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        await insert(previousInsertedCache, to: sut)
        let lastInsertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        await insert(lastInsertedCache, to: sut)

        let retrievedCache = try await expectNoThrowAsync(try await sut.retrieve(),
                                                          "Both insertions and retrieve should succeed with no throw",
                                                          file: file, line: line)
        
        XCTAssertEqual(retrievedCache, lastInsertedCache)
    }
}

// MARK: - Failable Insert

extension FailableInsertGalleryStoreSpecs where Self: XCTestCase {
    func assertThatInsertFailsOnInsertionError(on sut: GalleryStore,
                                               file: StaticString = #file, line: UInt = #line) async {
        let insertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        
        await expectThrowAsync(try await sut.insert(insertedCache),
                               "Insert should fail on no-write permission directory",
                               file: file, line: line)
    }
    
    func assertThatInsertHasNoSideEffectOnInsertionError(on sut: GalleryStore,
                                                         file: StaticString = #file, line: UInt = #line) async {
        let insertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        
        await expectThrowAsync(try await sut.insert(insertedCache),
                               "Insert should fail on no-write permission directory")
        
        await assertSUTReturnsEmpty(sut,
                                    "Insertion on insertion error should produce no side-effect",
                                    file: file, line: line)
    }
}

// MARK: - Delete

extension GalleryStoreSpecs where Self: XCTestCase {
    func assertThatDeleteSucceedsOnEmptyCache(on sut: GalleryStore,
                                              file: StaticString = #file, line: UInt = #line) async throws {
        try await expectNoThrowAsync(try await sut.delete(),
                                     "Deletion should succeed",
                                     file: file, line: line)
    }
    
    func assertThatDeleteHasNoSideEffectOnEmptyCache(on sut: GalleryStore,
                                                     file: StaticString = #file, line: UInt = #line) async throws {
        try await expectNoThrowAsync(try await sut.delete(),
                                     "Deletion should succeed")
        
        await assertSUTReturnsEmpty(sut,
                                    "Deletion should produce no side-effect",
                                    file: file, line: line)
    }
    
    func assertThatDeleteSucceedsOnNonEmptyCache(on sut: GalleryStore,
                                                 file: StaticString = #file, line: UInt = #line) async throws {
        let insertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        await insert(insertedCache, to: sut)
       
        try await expectNoThrowAsync(try await sut.delete(),
                                     "Deletion should succeed",
                                     file: file, line: line)
    }
    
    func assertThatDeleteHasNoSideEffectOnNonEmptyCache(on sut: GalleryStore,
                                                        file: StaticString = #file, line: UInt = #line) async throws {
        let insertedCache = LocalCache(gallery: uniqueLocalImages().local, timestamp: Date())
        await insert(insertedCache, to: sut)
        
        try await expectNoThrowAsync(try await sut.delete(),
                                     "Deletion should succeed")
        
        await expect(sut,
                     toRetrieve: nil,
                     "Cache should be empty after deletion",
                     file: file, line: line)
    }
}

// MARK: - Failable Delete

extension FailableDeleteGalleryStoreSpecs where Self: XCTestCase {
    func assertThatDeleteFailsOnDeletionError(on sut: GalleryStore,
                                              file: StaticString = #file, line: UInt = #line) async {
        await expectThrowAsync(try await sut.delete(),
                               "Delete should fail on no-write permission directory",
                               file: file, line: line)
    }
    
    func assertThatDeleteHasNoSideEffectOnDeletionError(on sut: GalleryStore,
                                                        testDirectory: URL,
                                                        file: StaticString = #file, line: UInt = #line) async {
        await expectThrowAsync(try await sut.delete(),
                               "Delete should fail on no-write permission directory",
                                file: file, line: line)
        
        // Note: verify possible side-effects when checking for file existance inside the caches folder.
        XCTAssertFalse(FileManager.default.fileExists(atPath: testDirectory.absoluteString))
    }
}
