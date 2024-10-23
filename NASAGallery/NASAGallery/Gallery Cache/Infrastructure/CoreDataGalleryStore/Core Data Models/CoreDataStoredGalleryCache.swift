//
//  CoreDataStoredGalleryCache.swift
//  NASAGallery
//
//  Created by Ivo on 10/10/24.
//

import CoreData

@objc(CoreDataStoredGalleryCache)
final class CoreDataStoredGalleryCache: NSManagedObject {
    @NSManaged public var timestamp: Date
    
    @NSManaged public var gallery: NSOrderedSet
}

// MARK: - Mapper

extension CoreDataStoredGalleryCache {
    static func from(local cache: LocalGalleryCache, in context: NSManagedObjectContext) -> CoreDataStoredGalleryCache {
        let storedImages: [CoreDataStoredGalleryImage] = cache.gallery.map { local in
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
        storedCache.timestamp = cache.timestamp
        storedCache.gallery = NSOrderedSet(array: storedImages)
       
        return storedCache
    }
}
