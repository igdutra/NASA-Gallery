//
//  GalleryItem.swift
//  NASAGallery
//
//  Created by Ivo on 17/11/23.
//

import Foundation

public struct GalleryItem: Equatable {
    let title: String
    let url: URL
    let date: String
    let explanation: String
    let mediaType: String
    
    // Optional fields
    let copyright: String?
    let hdurl: URL?
    let thumbnailUrl: URL?
    
    public init(title: String, url: URL, date: String, explanation: String, mediaType: String, copyright: String?, hdurl: URL?, thumbnailUrl: URL?) {
        self.title = title
        self.url = url
        self.date = date
        self.explanation = explanation
        self.mediaType = mediaType
        self.copyright = copyright
        self.hdurl = hdurl
        self.thumbnailUrl = thumbnailUrl
    }
}
