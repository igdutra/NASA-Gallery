//
//  GalleryStoreSpy.swift
//  NASAGallery
//
//  Created by Ivo on 15/03/24.
//

import Foundation
import NASAGallery

// Internal Type!
final class GalleryStoreSpy: GalleryStore {
    enum ReceivedMessage: Equatable {
        case delete
        case insert([LocalGalleryImage], Date)
        case retrieve
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
    
    public func deleteCachedGallery() throws {
        receivedMessages.append(.delete)
        
        if let error = stub?.deletionError {
            throw error
        }
    }
    
    public func insertCache(gallery: [LocalGalleryImage], timestamp: Date) throws {
        receivedMessages.append(.insert(gallery, timestamp))
        
        if let error = stub?.insertionError {
            throw error
        }
    }
    
    public func retrieve() {
        receivedMessages.append(.retrieve)
    }
}
