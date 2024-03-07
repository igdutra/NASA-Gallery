//
//  CacheGalleryUseCaseTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 06/03/24.
//

import XCTest

final class LocalGalleryLoader {
    let store: GalleryStore
    
    init(store: GalleryStore) {
        self.store = store
    }
    
    func save() throws {
        try store.deleteCachedGallery()
        store.insertCache()
    }
}

final class GalleryStore {
    enum ReceivedMessage: Equatable {
        case delete
        case insert
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
    
    func insertCache() {
        receivedMessages.append(.insert)
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
        
        try? sut.save()
        
        XCTAssert(store.receivedMessages.contains(.delete))
    }

    func test_save_onDeletionError_shouldNotInsertCache() {
        let (sut, store) = makeSUT()
        let deletionError = AnyError(message: "Deletion Error")
        store.stub(error: deletionError)
        
        try? sut.save()
        
        XCTAssertEqual(store.receivedMessages, [.delete])
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
 
