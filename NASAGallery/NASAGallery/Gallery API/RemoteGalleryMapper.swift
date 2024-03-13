//
//  RemoteGalleryMapper.swift
//  NASAGallery
//
//  Created by Ivo on 13/12/23.
//

import Foundation

enum RemoteGalleryMapper {
    
    private static let OK_200: Int = 200
    
    private struct APODItem: Decodable {
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
        
        var galleryImage: GalleryImage {
            GalleryImage(title: title, url: url, date: date, explanation: explanation, mediaType: mediaType, copyright: copyright, hdurl: hdurl, thumbnailUrl: thumbnailUrl)
        }
    }
    
    public static func map(_ data: Data, response: HTTPURLResponse) throws -> [GalleryImage] {
        guard response.statusCode == OK_200 else {
            throw RemoteGalleryLoader.Error.invalidData
        }
        
        let items = try JSONDecoder().decode([APODItem].self, from: data)
        let galleryImages = items.map { $0.galleryImage }
        
        return galleryImages
    }
}
