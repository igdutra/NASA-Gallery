//
//  SwiftDataGalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 14/11/24.
//

import Foundation
import SwiftData

@ModelActor
public final actor SwiftDataGalleryStore: GalleryStore {
    public func retrieve() async throws -> LocalGalleryCache? {
        do {
            let fetchDescriptor = FetchDescriptor<SwiftDataStoredGalleryCache>()
            guard let storedCache = try modelContext.fetch(fetchDescriptor).first else {
                return nil
            }
            let localGallery = storedCache.gallery
                .sorted { $0.sortIndex < $1.sortIndex }
                .map {
                    LocalGalleryImage(title: $0.title, url: $0.url, date: $0.date, explanation: $0.explanation, mediaType: $0.mediaType, copyright: $0.copyright, hdurl: $0.hdurl, thumbnailUrl: $0.thumbnailUrl)
                }
            
            return LocalGalleryCache(gallery: localGallery, timestamp: storedCache.timestamp)
        } catch {
            modelContext.rollback()
            throw error
        }
    }
    
    public func insert(_ cache: LocalGalleryCache) async throws {
        do {
            // Note: make sure to override previous cache
            try await delete()
            
            let storedCache = SwiftDataStoredGalleryCache(timestamp: cache.timestamp, gallery: [])
            
            let storedGallery = cache.gallery.enumerated().map { (index, image) in
                SwiftDataStoredGalleryImage(sortIndex: index,
                                            title: image.title,
                                            url: image.url,
                                            date: image.date,
                                            explanation: image.explanation,
                                            mediaType: image.mediaType,
                                            copyright: image.copyright,
                                            hdurl: image.hdurl,
                                            thumbnailUrl: image.thumbnailUrl,
                                            imageData: nil,
                                            cache: storedCache)
            }
            
            storedCache.gallery = storedGallery
            
            modelContext.insert(storedCache)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
    
    public func delete() async throws {
        do {
            let fetchDescriptor = FetchDescriptor<SwiftDataStoredGalleryCache>()
            let allCaches = try modelContext.fetch(fetchDescriptor)
            
            allCaches.forEach { modelContext.delete($0) }
            
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
