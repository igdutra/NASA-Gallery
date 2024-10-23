//
//  CoreDataMapper.swift
//  NASAGallery
//
//  Created by Ivo on 22/10/24.
//

import CoreData

enum CoreDataMapper {
    
    // MARK: - Stored to Local
    
    static func toLocalCache(from storedCache: CoreDataStoredGalleryCache) -> LocalGalleryCache {
        let images = toLocalImages(from: storedCache)
        return LocalGalleryCache(gallery: images, timestamp: storedCache.timestamp)
    }
    
    static func toLocalImages(from cache: CoreDataStoredGalleryCache) -> [LocalGalleryImage] {
        cache.gallery.compactMap { $0 as? CoreDataStoredGalleryImage }.map(toLocalImage(from:))
    }
    
    static func toLocalImage(from storedImage: CoreDataStoredGalleryImage) -> LocalGalleryImage {
        LocalGalleryImage(
            title: storedImage.title,
            url: storedImage.url,
            date: storedImage.date,
            explanation: storedImage.explanation,
            mediaType: storedImage.mediaType,
            copyright: storedImage.copyright,
            hdurl: storedImage.hdurl,
            thumbnailUrl: storedImage.thumbnailUrl
        )
    }
    
    // MARK: - Local to Stored
    
    static func toStoredCache(from localCache: LocalGalleryCache, in context: NSManagedObjectContext) -> CoreDataStoredGalleryCache {
        let storedImages = localCache.gallery.map { toStoredImage(from: $0, in: context) }
        
        let storedCache = CoreDataStoredGalleryCache(context: context)
        storedCache.timestamp = localCache.timestamp
        storedCache.gallery = NSOrderedSet(array: storedImages)
        
        return storedCache
    }
    
    static func toStoredImage(from localImage: LocalGalleryImage, in context: NSManagedObjectContext) -> CoreDataStoredGalleryImage {
        let storedImage = CoreDataStoredGalleryImage(context: context)
        storedImage.copyright = localImage.copyright
        storedImage.date = localImage.date
        storedImage.explanation = localImage.explanation
        storedImage.hdurl = localImage.hdurl
        // TODO: image will be done later in time
        storedImage.imageData = nil
        storedImage.mediaType = localImage.mediaType
        storedImage.thumbnailUrl = localImage.thumbnailUrl
        storedImage.title = localImage.title
        storedImage.url = localImage.url
        return storedImage
    }
}
