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
