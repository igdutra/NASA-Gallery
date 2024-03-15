//
//  LocalGalleryLoader.swift
//  NASAGallery
//
//  Created by Ivo on 13/03/24.
//

import Foundation

public final class LocalGalleryLoader {
    private static let MAX_DAYS_CACHE: Int = 2
    
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
        let cache = try store.retrieve()
        
        if validate(date1: cache.timestamp, date2: Date()) {
            return cache.gallery
        } else {
            throw NSError(domain: "NotFound", code: 0)
        }
    }
    
// vou ANOTA
// pra isso da certo, eu tenho que pega a DATE atual (de novo compara com a closure)
// e na verdade o RETRIEVE TEM QUE ME RETORNA UM COMBO, OU CHAMEMOS ISSO DE CAHCE: o role + timestamp! E AI pegando isso do retrieve eu vejo isso! hehehhe
    
    private func validate(date1: Date, date2: Date) -> Bool {
        // Get the current calendar
        let calendar = Calendar.current
        
        // Calculate the difference in days between the two dates
        let dateComponents = calendar.dateComponents([.day], from: date1, to: date2)
        
        // Check if the difference in days is exactly 2
        if let dayDifference = dateComponents.day, abs(dayDifference) < LocalGalleryLoader.MAX_DAYS_CACHE {
            return true
        } else {
            return false
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
