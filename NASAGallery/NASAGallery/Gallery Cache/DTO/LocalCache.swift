//
//  LocalCache.swift
//  NASAGallery
//
//  Created by Ivo on 15/03/24.
//

import Foundation

public class LocalCache {
    let gallery: [LocalGalleryImage]
    let timestamp: Date
    
    public init(gallery: [LocalGalleryImage], timestamp: Date) {
        self.gallery = gallery
        self.timestamp = timestamp
    }
}
