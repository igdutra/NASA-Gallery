//
//  LocalGalleryLoader.swift
//  NASAGallery
//
//  Created by Ivo on 13/03/24.
//

import Foundation

public final class LocalGalleryLoader: GalleryLoader {
    // TODO: add private struct InvalidCache: Error {}
    private let cachePolicy: GalleryCachePolicy
    private let store: GalleryStore
    
    // TODO: move to cons
    /* Author note on date injection:
     The essential feed injects a closure "currentDate: () -> Date" in the init, because it uses constructor injection rather then parameter injection (current setup)
     By doing so, we move away the responsability to dictate the date to the composition root, rather then the caller.
     
     When performing composition, revisit this.
    */
    
    public init(store: GalleryStore) {
        self.store = store
        self.cachePolicy = GalleryCachePolicy()
    }
    
    // MARK: - Public methods
    
    // TODO: Move to constructor injection with closure?
    public func save(gallery: [GalleryImage], timestamp: Date) async throws {
        try await store.delete()
        try await store.insert(LocalGalleryCache(gallery: gallery.toLocal(), timestamp: timestamp))
    }
    
    public func load() async throws -> [GalleryImage] {
        guard let cache = try await store.retrieve(),
              cachePolicy.validate(cache.timestamp, against: Date())
        else { return [] }
        
        return cache.gallery.toModel()
    }
    
    // Note: This is a prime example of a command function only! (CQS separation). It can produce side-effects (cache deletion)
    public func validateCache() async throws {
        do {
            guard let cache = try await store.retrieve() else { return }
            let isCacheExpired = !cachePolicy.validate(cache.timestamp, against: Date())
            if isCacheExpired {
                try await store.delete()
            }
        } catch {
            try await store.delete()
            throw error
        }
    }
}

// MARK: - Array Extension
// Moving the mapping logic from RemoteAPODItem -> GalleryImage to RemoteGalleryLoader reduces the pointing arrows to GalleryImage!
private extension Array where Element == GalleryImage {
    func toLocal() -> [LocalGalleryImage] {
        return map { LocalGalleryImage(title: $0.title, url: $0.url, date: $0.date, explanation: $0.explanation, mediaType: $0.mediaType, copyright: $0.copyright, hdurl: $0.hdurl, thumbnailUrl: $0.thumbnailUrl) }
    }
}

private extension Array where Element == LocalGalleryImage {
    func toModel() -> [GalleryImage] {
        return map { GalleryImage(title: $0.title, url: $0.url, date: $0.date, explanation: $0.explanation, mediaType: $0.mediaType, copyright: $0.copyright, hdurl: $0.hdurl, thumbnailUrl: $0.thumbnailUrl) }
    }
}

