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
        container = try NSPersistentContainer.load(modelName: "GalleryStore", in: storeBundle, storeURL: storeURL)
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
