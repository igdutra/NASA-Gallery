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
    private let container: NSPersistentContainer

    public init(storeBundle: Bundle = .main, storeURL: URL) throws {
        container = try NSPersistentContainer.load(modelName: "GalleryStore")
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

// MARK: - NSPersistentContainer

private extension NSPersistentContainer {
    static func load(modelName: String) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: modelName)
        var loadError: Error?
        
        container.loadPersistentStores { _, error in
            if let error {
                loadError = error
            }
        }
        
        if let loadError {
            throw loadError
        }

        return container
    }
}
