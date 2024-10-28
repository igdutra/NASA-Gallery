//
//  CoreDataGalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 08/10/24.
//

import CoreData

public final class CoreDataGalleryStore: GalleryStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init(storeBundle: Bundle = .main, storeURL: URL) throws {
        container = try NSPersistentContainer.load(modelName: "GalleryStore", in: storeBundle, storeURL: storeURL)
        context = container.newBackgroundContext()
    }
    
    // MARK: - Gallery Store
    
    public func delete() async throws {
        try await context.perform { [context] in
            try CoreDataStoredGalleryCache.deleteCache(in: context)
            try context.save()
            // Note: in a normal scenario would make sense to use context.hasChanges but here, since delete will only get executed if there's a value, then there's no need to check it first.
        }
    }
    
    public func insert(_ cache: LocalGalleryCache) async throws {
        try await context.perform { [context] in
            try CoreDataStoredGalleryCache.deleteCache(in: context)
            
            _ = CoreDataMapper.toStoredCache(from: cache, in: context)
            
            guard context.hasChanges else { return }
            
            try context.save()
        }
    }
    
    public func retrieve() async throws -> LocalGalleryCache? {
        return try await context.perform { [context] in
            let storedCache = try CoreDataStoredGalleryCache.find(in: context)
    
            return storedCache.map(CoreDataMapper.toLocalCache(from:))
        }
    }
}

// MARK: - Helpers

extension CoreDataStoredGalleryCache {
    // Note: by wrapping the fetch with a function that returns optional, we are able to return nil inside the retrieve
    static func find(in context: NSManagedObjectContext) throws -> CoreDataStoredGalleryCache? {
        let request = NSFetchRequest<CoreDataStoredGalleryCache>(entityName: entity().name!)
        request.returnsObjectsAsFaults = false // Core Data optimization
        return try context.fetch(request).first
    }
    
    // Note: to optimize insert function, we do not use the public API, so that we can save the context only once.
    static func deleteCache(in context: NSManagedObjectContext) throws {
        try find(in: context).map(context.delete)
    }
}

// MARK: - CoreData Initialization: NSPersistentContainer & NSManagedObjectModel

private extension NSPersistentContainer {
    enum LoadingError: Error {
        case modelNotFound
        case failedToLoadPersistentStores(Error)
    }
    
    static func load(modelName: String, in bundle: Bundle, storeURL: URL) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(name: modelName, in: bundle) else {
            throw LoadingError.modelNotFound
        }
        
        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        
        // Inject the /dev/null
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [storeDescription]
        
        var loadError: Error?
        container.loadPersistentStores { loadError = $1 }
        try loadError.map { throw $0 }
        
        return container
    }
}

private extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        return bundle
            .url(forResource: name, withExtension: "momd")
            .flatMap { NSManagedObjectModel(contentsOf: $0) }
    }
}

// MARK: - Note on functional approach
/*
 
// old approach:
try await context.perform { [context] in
    if let storedCache = try CoreDataStoredGalleryCache.find(in: context) {
        context.delete(storedCache)
        guard context.hasChanges else { return }
        try context.save()
    }
}
// was replaced by
 try CoreDataStoredGalleryCache
     .find(in: context)
     .map(context.delete)
     .map(context.save)
 
 Now both of these were placed in favor of deleteCache helper, enforcing that on insert, we call context.save only once.
*/
