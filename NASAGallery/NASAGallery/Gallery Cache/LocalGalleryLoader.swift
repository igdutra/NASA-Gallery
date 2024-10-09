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
    
    #warning("Verify against Date injection: should it be a closure?")
    public init(store: GalleryStore) {
        self.store = store
        self.cachePolicy = GalleryCachePolicy()
    }
    
    // MARK: - Public methods
    
    // TODO: Verify about injecting closure as date
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

