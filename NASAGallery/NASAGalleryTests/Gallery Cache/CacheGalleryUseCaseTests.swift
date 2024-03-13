//
//  CacheGalleryUseCaseTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 06/03/24.
//

import XCTest
import NASAGallery

/* Author Notes on RemoteGalleryLoaderTests
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
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        
        try? sut.save(gallery: [], timestamp: Date())
        
        XCTAssert(store.receivedMessages.contains(.delete))
    }
    
    // MARK: - Error Cases

    func test_save_onDeletionError_shouldNotInsertCache() {
        let (sut, store) = makeSUT()
        let deletionError = AnyError(message: "Deletion Error")
        store.stub(deletionError: deletionError, insertionError: nil)
        
        try? sut.save(gallery: [], timestamp: Date())
        
        XCTAssertEqual(store.receivedMessages, [.delete])
    }
    
    func test_save_onDeletionError_fails() {
        let (sut, store) = makeSUT()
        let deletionError = AnyError(message: "Deletion Error")
        store.stub(deletionError: deletionError, insertionError: nil)
        
        assertSaveThrowsError(sut: sut,
                              expectedError: deletionError)
    }
    
    func test_save_onInsertionError_fails() {
        let (sut, store) = makeSUT()
        let insertionError = AnyError(message: "Insertion Error")
        store.stub(deletionError: nil, insertionError: insertionError)
        
        assertSaveThrowsError(sut: sut,
                              expectedError: insertionError)
    }
    
    // MARK: - Success Case
    
    func test_save_onSuccessfulDeletion_requestsNewCacheInsertionWithTimestamp() {
        let (sut, store) = makeSUT()
        let gallery = uniqueLocalImages()
        let timestamp = Date()
        store.stub(deletionError: nil, insertionError: nil) // Making test explicit that deletion error is nil
        
        try? sut.save(gallery: gallery.images, timestamp: timestamp)
        
        XCTAssertEqual(store.receivedMessages, [.delete, .insert(gallery.local, timestamp)])
    }
    
    func test_save_onSuccessfulCacheInsertion_succeeds() {
        let (sut, store) = makeSUT()
        let gallery = uniqueLocalImages()
        let timestamp = Date()
        store.stub(deletionError: nil, insertionError: nil)
        
        do {
            try sut.save(gallery: gallery.images, timestamp: timestamp)
        } catch {
            XCTFail("Expected command to succeed, got \(error) instead")
        }
    }
}

// MARK: - Helpers

private extension CacheGalleryUseCaseTests {
    func makeSUT() -> (sut: LocalGalleryLoader, store: GalleryStoreSpy) {
        let store = GalleryStoreSpy()
        let sut = LocalGalleryLoader(store: store)
        
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(store)
        
        return (sut, store)
    }
    
    func uniqueLocalImages() -> (local: [LocalGalleryImage], images: [GalleryImage]) {
        let images = makeImages()
        let local = images.model.map {
            LocalGalleryImage(title: $0.title, url: $0.url, date: $0.date, explanation: $0.explanation, mediaType: $0.mediaType, copyright: $0.copyright, hdurl: $0.hdurl, thumbnailUrl: $0.thumbnailUrl)
        }
        return (local, images.model)
    }
    
    // MARK: - Assertions
    
    func assertSaveThrowsError<ErrorType: Error & Equatable>(sut: LocalGalleryLoader,
                                                             expectedError: ErrorType,
                                                             gallery: [GalleryImage] = [], timestamp: Date = Date(),
                                                             file: StaticString = #filePath, line: UInt = #line) {
        do {
            try sut.save(gallery: gallery, timestamp: timestamp)
            XCTFail("Expected save to throw \(expectedError), but it succeeded")
        } catch let error as ErrorType {
            XCTAssertEqual(error, expectedError, "Expected \(expectedError), got \(error) instead", file: file, line: line)
        } catch {
            XCTFail("Expected error to be AnyError, got \(error) instead", file: file, line: line)
        }
    }
}

// MARK: - Spy
private extension CacheGalleryUseCaseTests {
    final class GalleryStoreSpy: GalleryStore {
        enum ReceivedMessage: Equatable {
            case delete
            case insert([LocalGalleryImage], Date)
        }
        
        private(set) var receivedMessages = [ReceivedMessage]()
        
        private struct Stub {
            let deletionError: Error?
            let insertionError: Error?
        }
        
        private var stub: Stub?
        
        func stub(deletionError: Error?, insertionError: Error?) {
            stub = Stub(deletionError: deletionError, insertionError: insertionError)
        }
        
        // MARK: - GalleryStore
        
        func deleteCachedGallery() throws {
            receivedMessages.append(.delete)
            
            if let error = stub?.deletionError {
                throw error
            }
        }
        
        func insertCache(gallery: [LocalGalleryImage], timestamp: Date) throws {
            receivedMessages.append(.insert(gallery, timestamp))
            
            if let error = stub?.insertionError {
                throw error
            }
        }
    }
}
