//
//  CacheGalleryUseCaseTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 06/03/24.
//

import XCTest
import NASAGallery

/* Author Notes on CacheGalleryUseCaseTests
 - Cache Use Case is the Local Store Save command.
 - The idea was to test drive this implementation, following the use case definition as guideline to name the tests!
 
 ### Cache APOD Use Case

 #### Data:
 - APOD gallery

 #### Primary course (happy path):
 1. Execute "Save APOD gallery" command with the given APOD gallery.
 2. System deletes old cache data.
 3. System encodes APOD gallery for caching. (infrastructure)
 4. System timestamps the new cache.
 5. System saves the cache with new data.
 6. System delivers success message.

 #### Deleting error course (sad path):
 1. System delivers error.

 #### Empty cache course (sad path):
 1. System delivers error.
*/
final class CacheGalleryUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() async {
        let (sut, store) = makeSUT()
        
        try? await sut.save(gallery: [], timestamp: Date())
        
        XCTAssert(store.receivedMessages.contains(.delete))
    }
    
    // MARK: - Error Cases

    func test_save_onDeletionError_failsToRequestCacheInsertion() async {
        let (sut, store) = makeSUT()
        let deletionError = AnyError(message: "Deletion Error")
        store.stub(deletionError: deletionError, insertionError: nil)
        
        try? await sut.save(gallery: [], timestamp: Date())
        
        XCTAssertEqual(store.receivedMessages, [.delete])
    }
    
    func test_save_onDeletionError_fails() async {
        let (sut, store) = makeSUT()
        let deletionError = AnyError(message: "Deletion Error")
        store.stub(deletionError: deletionError, insertionError: nil)
        
        await assertSaveThrowsError(sut: sut,
                                    expectedError: deletionError)
    }
    
    func test_save_onInsertionError_fails() async {
        let (sut, store) = makeSUT()
        let insertionError = AnyError(message: "Insertion Error")
        store.stub(deletionError: nil, insertionError: insertionError)
        
        await assertSaveThrowsError(sut: sut,
                                    expectedError: insertionError)
    }
    
    // MARK: - Success Case
    
    func test_save_onSuccessfulDeletion_succeedsToRequestNewCacheInsertionWithTimestamp() async {
        let (sut, store) = makeSUT()
        let gallery = uniqueLocalImages()
        let timestamp = Date()
        store.stub(deletionError: nil, insertionError: nil) // Making test explicit that deletion error is nil
        
        try? await sut.save(gallery: gallery.images, timestamp: timestamp)
        
        XCTAssertEqual(store.receivedMessages, [.delete, .insert(LocalGalleryCache(gallery: gallery.local, timestamp: timestamp))])
    }
    
    func test_save_onSuccessfulCacheInsertion_succeeds() async {
        let (sut, store) = makeSUT()
        let gallery = uniqueLocalImages()
        let timestamp = Date()
        store.stub(deletionError: nil, insertionError: nil)
        
        do {
            try await sut.save(gallery: gallery.images, timestamp: timestamp)
        } catch {
            XCTFail("Expected command to succeed, got \(error) instead")
        }
    }
}

// MARK: - Helpers

private extension CacheGalleryUseCaseTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalGalleryLoader, store: GalleryStoreSpy) {
        let store = GalleryStoreSpy()
        let sut = LocalGalleryLoader(store: store)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        
        return (sut, store)
    }
    
    // MARK: - Assertions
    
    func assertSaveThrowsError<ErrorType: Error & Equatable>(sut: LocalGalleryLoader,
                                                             expectedError: ErrorType,
                                                             gallery: [GalleryImage] = [], timestamp: Date = Date(),
                                                             file: StaticString = #filePath, line: UInt = #line) async {
        do {
            try await sut.save(gallery: gallery, timestamp: timestamp)
            XCTFail("Expected save to throw \(expectedError), but it succeeded")
        } catch let error as ErrorType {
            XCTAssertEqual(error, expectedError, "Expected \(expectedError), got \(error) instead", file: file, line: line)
        } catch {
            XCTFail("Expected error to be AnyError, got \(error) instead", file: file, line: line)
        }
    }
}
