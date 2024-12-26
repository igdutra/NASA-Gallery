//
//  SwiftDataStoredGalleryCache.swift
//  NASAGallery
//
//  Created by Ivo on 20/11/24.
//

import Foundation
import SwiftData

@Model
public final class SwiftDataStoredGalleryCache {
    @Relationship(deleteRule: .cascade, inverse: \SwiftDataStoredGalleryImage.cache)
    var gallery: [SwiftDataStoredGalleryImage]
    var timestamp: Date
    
    init(timestamp: Date,
         gallery: [SwiftDataStoredGalleryImage] = []) {
        self.timestamp = timestamp
        self.gallery = gallery
    }
}
