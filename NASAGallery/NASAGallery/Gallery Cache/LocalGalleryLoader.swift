//
//  LocalGalleryLoader.swift
//  NASAGallery
//
//  Created by Ivo on 13/03/24.
//

import Foundation

public final class LocalGalleryLoader {
    private let maxCacheAgeInDays: Int = 2
    private let calendar = Calendar(identifier: .gregorian)
    
    private let store: GalleryStore
    
    public init(store: GalleryStore) {
        self.store = store
    }
    
    // MARK: - Public methods
    
    // TODO: Verify about injecting closure as date
    public func save(gallery: [GalleryImage], timestamp: Date) throws {
        try store.deleteCachedGallery()
        try store.insertCache(gallery: gallery.toLocal(), timestamp: timestamp)
    }
    
    public func load() throws -> [LocalGalleryImage] {
        do {
            let cache = try store.retrieve()
            
            if validate(cache.timestamp) {
                return cache.gallery
            } else {
                return []
            }
        } catch {
            try store.deleteCachedGallery()
            throw error
        }
    }
    
    // TODO: verify again Date() against currentDate() closure
    private func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return Date() < maxCacheAge
    }
}

// MARK: - Array Extension
// Moving the mapping logic from RemoteAPODItem -> GalleryImage to RemoteGalleryLoader reduces the pointing arrows to GalleryImage!
private extension Array where Element == GalleryImage {
    func toLocal() -> [LocalGalleryImage] {
        return map { LocalGalleryImage(title: $0.title, url: $0.url, date: $0.date, explanation: $0.explanation, mediaType: $0.mediaType, copyright: $0.copyright, hdurl: $0.hdurl, thumbnailUrl: $0.thumbnailUrl) }
    }
}
