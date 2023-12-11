//
//  GalleryItem.swift
//  NASAGallery
//
//  Created by Ivo on 17/11/23.
//

import Foundation

// TODO: remove codingKeys and decodable from model

public struct GalleryItem: Equatable {
    public let title: String
    public let url: URL
    public let date: String
    public let explanation: String
    public let mediaType: String
    
    // Optional fields
    public let copyright: String?
    public let hdurl: URL?
    public let thumbnailUrl: URL?
    
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
