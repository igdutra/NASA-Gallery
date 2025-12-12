//
//  GalleryImage.swift
//  NASAGallery
//
//  Created by Ivo on 17/11/23.
//

import Foundation

/* NOTE Possible Idea for UI Module
 
 This is the raw Model
 when dealing with UI, there are some variations
 for example, hdurl will not happen when on video type
 
 Suggestions:
 - create some child types from these
 - or create enum (careful Open closed principal!) for mediaType
 
*/

public struct GalleryImage: Equatable {
    public let title: String
    public let url: URL
    public let date: Date
    public let explanation: String
    public let mediaType: String
    
    // Optional fields
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

// TODO: when creating a new ViewData that the view will actually consume, make that hashable and sendable

extension GalleryImage: Hashable, Sendable { }
