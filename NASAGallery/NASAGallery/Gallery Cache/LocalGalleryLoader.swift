//
//  LocalGalleryLoader.swift
//  NASAGallery
//
//  Created by Ivo on 13/03/24.
//

import Foundation

public struct GalleryCachePolicy {
    private let maxCacheAgeInDays: Int = 2
    private let calendar = Calendar(identifier: .gregorian)
    
    #warning("Verify against Date injection: should it be a closure?")
    public func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return Date() < maxCacheAge
    }
}

public final class LocalGalleryLoader {
    // TODO: add private struct InvalidCache: Error {}
    private let cachePolicy: GalleryCachePolicy
    private let store: GalleryStore
    
    public init(store: GalleryStore) {
        self.store = store
        self.cachePolicy = GalleryCachePolicy()
    }
    
    // MARK: - Public methods
    
    // TODO: Verify about injecting closure as date
    public func save(gallery: [GalleryImage], timestamp: Date) throws {
        try store.deleteCachedGallery()
        try store.insertCache(gallery: gallery.toLocal(), timestamp: timestamp)
    }
    
    public func load() throws -> [LocalGalleryImage] {
        let cache = try store.retrieve()
        
        guard cachePolicy.validate(cache.timestamp) else { return [] }
        
        return cache.gallery
    }
    // Note: This is a prime example of a command function only! (CQS separation). It can produce side-effects (cache deletion)
    public func validateCache() throws {
        do {
            let cache = try store.retrieve()
            
            if !cachePolicy.validate(cache.timestamp) {
                try store.deleteCachedGallery()
            }
        } catch {
            try store.deleteCachedGallery()
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
