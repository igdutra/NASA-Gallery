//
//  CacheHelpers.swift
//  NASAGallery
//
//  Created by Ivo on 15/03/24.
//

import Foundation
import NASAGallery

func uniqueLocalImages(title: String = "") -> (local: [LocalGalleryImage], images: [GalleryImage]) {
    let images = makeImages(title: title)
    let local = images.model.map {
        LocalGalleryImage(title: $0.title, url: $0.url, date: $0.date, explanation: $0.explanation, mediaType: $0.mediaType, copyright: $0.copyright, hdurl: $0.hdurl, thumbnailUrl: $0.thumbnailUrl)
    }
    return (local, images.model)
}

// Cache DSL, domain Language
var cacheMaxAgeLimitTimestamp: Date {
    let currentDate = Date()
    return currentDate.adding(days: -2)
}
