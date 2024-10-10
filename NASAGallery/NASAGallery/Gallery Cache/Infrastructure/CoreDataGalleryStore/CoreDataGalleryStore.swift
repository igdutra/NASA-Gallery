//
//  CoreDataGalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 08/10/24.
//

import CoreData

// TODO: add this optimization  // Verify that the context has uncommitted changes.
//guard persistentContainer.viewContext.hasChanges else { return }

// TODO: add on wiki step by step: add file "data model"
// TODO: codegen, manual

public final class CoreDataGalleryStore: GalleryStore {
    
    private let storeBundle: Bundle
    private let storeURL: URL
    
    public init(storeBundle: Bundle, storeURL: URL) throws {
        self.storeBundle = storeBundle
        self.storeURL = storeURL
    }
    
    // MARK: - Gallery Store
    
    public func delete() async throws {
        
    }
    
    public func insert(_ cache: LocalGalleryCache) async throws {
        
    }
    
    public func retrieve() async throws -> LocalGalleryCache? {
        return nil
    }
    
    // MARK: - Helpers
}
