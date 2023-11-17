//
//  APODItem.swift
//  NASAGallery
//
//  Created by Ivo on 17/11/23.
//

import Foundation

struct APODItem {
    let title: String
    let url: URL
    let date: String
    let explanation: String
    let mediaType: String
    
    // Optional fields
    let copyright: String?
    let hdurl: URL?
    let thumbnailUrl: URL?

    enum CodingKeys: String, CodingKey {
        case date, explanation, title, url, hdurl
        case mediaType = "media_type"
        case thumbnailUrl = "thumbnail_url"
        case copyright
    }
}
