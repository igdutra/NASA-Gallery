//
//  SwiftDataStoredGalleryImage.swift
//  NASAGallery
//
//  Created by Ivo on 20/11/24.
//

import Foundation
import SwiftData

@Model
public final class SwiftDataStoredGalleryImage {
    // Note: without an explicit sortIndex, swiftData will retrieve the elements in the array at a random order
    var sortIndex: Int
    
    @Attribute(.unique) var title: String
    var url: URL
    var date: Date
    var explanation: String
    var mediaType: String

    var copyright: String?
    
    var hdurl: URL?
    var thumbnailUrl: URL?

    var imageData: Data?
    
    // Note: as per SwiftData requirement to satisfy the "Cascade" delete rule, either this must be optional or give it a default value
    var cache: SwiftDataStoredGalleryCache?
    
    init(sortIndex: Int,
         title: String,
         url: URL,
         date: Date,
         explanation: String,
         mediaType: String,
         copyright: String? = nil,
         hdurl: URL? = nil,
         thumbnailUrl: URL? = nil,
         imageData: Data? = nil,
         cache: SwiftDataStoredGalleryCache) {
        self.sortIndex = sortIndex
        self.title = title
        self.url = url
        self.date = date
        self.explanation = explanation
        self.mediaType = mediaType
        self.copyright = copyright
        self.hdurl = hdurl
        self.thumbnailUrl = thumbnailUrl
        self.imageData = imageData
        self.cache = cache
    }
}
