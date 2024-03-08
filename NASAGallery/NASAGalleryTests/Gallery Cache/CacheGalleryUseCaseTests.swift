//
//  CacheGalleryUseCaseTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 06/03/24.
//

import XCTest
import NASAGallery

final class LocalGalleryLoader {
    let store: GalleryStore
    
    init(store: GalleryStore) {
        self.store = store
    }
    
    // TODO: Verify about injecting closure as date
    func save(gallery: [GalleryItem], timestamp: Date) throws {
        try store.deleteCachedGallery()
        store.insertCache(gallery: gallery, timestamp: timestamp)
    }
}

final class GalleryStore {
    enum ReceivedMessage: Equatable {
        case delete
        case insert([GalleryItem], Date)
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    private struct Stub {
        let error: Error?
    }
    
    private var stub: Stub?
    
    func stub(error: Error?) {
        stub = Stub(error: error)
    }
    
    // MARK: - Methods
    
    func deleteCachedGallery() throws {
        receivedMessages.append(.delete)
        
        if let error = stub?.error {
            throw error
        }
    }
    
    func insertCache(gallery: [GalleryItem], timestamp: Date) {
        receivedMessages.append(.insert(gallery, timestamp))
    }
}

// Cache Use Case is the Local Store Save command.
final class CacheGalleryUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let (sut, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        
        try? sut.save(gallery: [], timestamp: Date())
        
        XCTAssert(store.receivedMessages.contains(.delete))
    }

    func test_save_onDeletionError_shouldNotInsertCache() {
        let (sut, store) = makeSUT()
        let deletionError = AnyError(message: "Deletion Error")
        store.stub(error: deletionError)
        
        try? sut.save(gallery: [], timestamp: Date())
        
        XCTAssertEqual(store.receivedMessages, [.delete])
    }
    
    func test_save_onSuccessfulDeletion_requestsNewCacheInsertionWithTimestamp() {
        let (sut, store) = makeSUT()
        let gallery: [GalleryItem] = makeItems().model
        let timestamp = Date()
        
        store.stub(error: nil) // Making test explicit that deletion error is nil
        
        try? sut.save(gallery: gallery, timestamp: timestamp)
        
        XCTAssertEqual(store.receivedMessages, [.delete, .insert(gallery, timestamp)])
    }
   
}

// MARK: - Helpers

private extension CacheGalleryUseCaseTests {
    func makeSUT() -> (sut: LocalGalleryLoader, store: GalleryStore) {
        let store = GalleryStore()
        let sut = LocalGalleryLoader(store: store)
        
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(store)
        
        return (sut, store)
    }
}
 
