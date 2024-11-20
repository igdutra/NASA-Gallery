//
//  SwiftDataStoredGalleryImage.swift
//  NASAGallery
//
//  Created by Ivo on 20/11/24.
//

import Foundation
import SwiftData

@Model
final class SwiftDataStoredGalleryImage {
    var title: String
    @Attribute(.unique) var url: URL
    var date: Date
    var explanation: String
    var mediaType: String

    var copyright: String?
    var hdurl: URL?
    var thumbnailUrl: URL?

    var imageData: Data?

    var cache: SwiftDataStoredGalleryCache
    
    init(title: String,
         url: URL,
         date: Date,
         explanation: String,
         mediaType: String,
         copyright: String? = nil,
         hdurl: URL? = nil,
         thumbnailUrl: URL? = nil,
         imageData: Data? = nil,
         cache: SwiftDataStoredGalleryCache) {
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
