//
//  LocalGalleryLoader.swift
//  NASAGallery
//
//  Created by Ivo on 13/03/24.
//

import Foundation

public final class LocalGalleryLoader {
    private let store: GalleryStore
    
    public init(store: GalleryStore) {
        self.store = store
    }
    
    // TODO: Verify about injecting closure as date
    public func save(gallery: [GalleryImage], timestamp: Date) throws {
        try store.deleteCachedGallery()
        try store.insertCache(gallery: gallery.toLocal(), timestamp: timestamp)
    }
    
    public func load() throws -> [LocalGalleryImage] {
       return try store.retrieve()
    }
}

// MARK: - Array Extension
// Moving the mapping logic from RemoteAPODItem -> GalleryImage to RemoteGalleryLoader reduces the pointing arrows to GalleryImage!
private extension Array where Element == GalleryImage {
    func toLocal() -> [LocalGalleryImage] {
        return map { LocalGalleryImage(title: $0.title, url: $0.url, date: $0.date, explanation: $0.explanation, mediaType: $0.mediaType, copyright: $0.copyright, hdurl: $0.hdurl, thumbnailUrl: $0.thumbnailUrl) }
    }
}
