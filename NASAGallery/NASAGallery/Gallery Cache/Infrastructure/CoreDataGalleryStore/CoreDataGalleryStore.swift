//
//  CoreDataGalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 08/10/24.
//

import CoreData

// TODO: add this optimization  // Verify that the context has uncommitted changes.
//guard persistentContainer.viewContext.hasChanges else { return }

public final class CoreDataGalleryStore: GalleryStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init(storeBundle: Bundle = .main, storeURL: URL) throws {
        container = try NSPersistentContainer.load(modelName: "GalleryStore", storeURL: storeURL)
        context = container.newBackgroundContext()
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
    static func load(modelName: String, storeURL: URL) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: modelName)
        
        // Inject the /dev/null
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [storeDescription]
        
        var loadError: Error?
        container.loadPersistentStores { loadError = $1 }
        try loadError.map { throw $0 }
        
        return container
    }
}
