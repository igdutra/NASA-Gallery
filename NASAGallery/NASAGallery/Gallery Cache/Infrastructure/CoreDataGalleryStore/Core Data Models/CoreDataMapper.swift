//
//  CoreDataMapper.swift
//  NASAGallery
//
//  Created by Ivo on 22/10/24.
//

import CoreData

enum CoreDataMapper {
    
    // MARK: - Local to Stored
    
    static func localImage(from storedImage: CoreDataStoredGalleryImage) -> LocalGalleryImage {
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
    
    // MARK: - Stored to Local
    
    static func storedCache(from localCache: LocalGalleryCache, in context: NSManagedObjectContext) -> CoreDataStoredGalleryCache {
        let storedImages: [CoreDataStoredGalleryImage] = localCache.gallery.map { local in
            let storedImage = CoreDataStoredGalleryImage(context: context)
            storedImage.copyright = local.copyright
            storedImage.date = local.date
            storedImage.explanation = local.explanation
            storedImage.hdurl = local.hdurl
            // TODO: image will be done later in time
            storedImage.imageData = nil
            storedImage.mediaType = local.mediaType
            storedImage.thumbnailUrl = local.thumbnailUrl
            storedImage.title = local.title
            storedImage.url = local.url
            return storedImage
        }
        
        let storedCache = CoreDataStoredGalleryCache(context: context)
        storedCache.timestamp = localCache.timestamp
        storedCache.gallery = NSOrderedSet(array: storedImages)
        
        return storedCache
    }
}
