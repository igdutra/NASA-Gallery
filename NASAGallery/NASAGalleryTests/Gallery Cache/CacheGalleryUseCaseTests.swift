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
    
    func save() {
        store.deleteCachedGallery()
    }
}

final class GalleryStore {
    enum ReceivedMessage: Equatable {
        case delete
        case insert
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    func deleteCachedGallery() {
        receivedMessages.append(.delete)
    }

}

final class CacheGalleryUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let store = GalleryStore()
        let sut = LocalGalleryLoader(store: store)
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let store = GalleryStore()
        let sut = LocalGalleryLoader(store: store)
        
        sut.save()
        
        XCTAssertEqual(store.receivedMessages, [.delete])
    }
}
