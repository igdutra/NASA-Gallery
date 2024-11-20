//
//  CoreDataStoredGalleryImage.swift
//  NASAGallery
//
//  Created by Ivo on 10/10/24.
//

import CoreData

@objc(CoreDataStoredGalleryImage)
final class CoreDataStoredGalleryImage: NSManagedObject {
    @NSManaged public var title: String
    @NSManaged public var url: URL
    @NSManaged public var date: Date
    @NSManaged public var explanation: String
    @NSManaged public var mediaType: String

    @NSManaged public var copyright: String?
    @NSManaged public var hdurl: URL?
    @NSManaged public var thumbnailUrl: URL?

    @NSManaged public var imageData: Data?
     
    @NSManaged public var cache: CoreDataStoredGalleryCache
}
