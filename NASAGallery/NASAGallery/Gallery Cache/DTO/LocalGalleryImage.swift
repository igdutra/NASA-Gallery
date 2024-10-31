//
//  LocalGalleryImage.swift
//  NASAGallery
//
//  Created by Ivo on 13/03/24.
//

import Foundation

public struct LocalGalleryImage: Equatable {
    public let title: String
    public let url: URL
    public let date: Date
    public let explanation: String
    public let mediaType: String
    
    public let copyright: String?
    public let hdurl: URL?
    public let thumbnailUrl: URL?
    
    public init(title: String, url: URL, date: Date, explanation: String, mediaType: String, copyright: String?, hdurl: URL?, thumbnailUrl: URL?) {
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
