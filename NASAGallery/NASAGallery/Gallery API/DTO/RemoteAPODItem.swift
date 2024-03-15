//
//  RemoteAPODItem.swift
//  NASAGallery
//
//  Created by Ivo on 13/03/24.
//

import Foundation

// Internal type!
struct RemoteAPODItem: Decodable {
    let title: String
    let url: URL
    let date: String
    let explanation: String
    let mediaType: String
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
