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
        case insert(LocalGalleryCache)
        case retrieve
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    private struct Stub {
        let deletionError: Error?
        let insertionError: Error?
        let retrivalError: Error?
        let retrivalReturn: LocalGalleryCache?
    }
    
    private var stub: Stub?
    
    func stub(deletionError: Error? = nil,
              insertionError: Error? = nil,
              retrivalError: Error? = nil,
              retrivalReturn: LocalGalleryCache? = nil) {
        stub = Stub(deletionError: deletionError,
                    insertionError: insertionError,
                    retrivalError: retrivalError,
                    retrivalReturn: retrivalReturn)
    }
    
    // MARK: - GalleryStore
    
    public func delete() throws {
        receivedMessages.append(.delete)
        
        if let error = stub?.deletionError {
            throw error
        }
    }
    
    public func insert(_ cache: LocalGalleryCache) throws {
        receivedMessages.append(.insert(cache))
        
        if let error = stub?.insertionError {
            throw error
        }
    }
    
    public func retrieve() throws -> LocalGalleryCache? {
        receivedMessages.append(.retrieve)
        
        if let error = stub?.retrivalError {
            throw error
        } else if let expectedReturn = stub?.retrivalReturn {
            return expectedReturn
        }
        
        // If there's no return or error, cache is empty!
        return LocalGalleryCache(gallery: [], timestamp: Date())
    }
}
