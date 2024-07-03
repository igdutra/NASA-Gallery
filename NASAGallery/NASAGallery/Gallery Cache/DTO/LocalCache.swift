//
//  LocalCache.swift
//  NASAGallery
//
//  Created by Ivo on 15/03/24.
//

import Foundation

// Note: could also be a simple 
// public typealias LocalCache = (gallery: [LocalGalleryImage], timestamp: Date)
public struct LocalCache {
    public let gallery: [LocalGalleryImage]
    public let timestamp: Date
    
    public init(gallery: [LocalGalleryImage], timestamp: Date) {
        self.gallery = gallery
        self.timestamp = timestamp
    }
}
