//
//  RemoteGalleryLoader.swift
//  NASAGallery
//
//  Created by Ivo on 29/11/23.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL) async throws -> (HTTPURLResponse, Data)
}

public class RemoteGalleryLoader {
    private let client: HTTPClient
    private let url: URL
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load() async throws -> [GalleryItem] {
        guard let (response, data) = try? await client.get(from: url) else {
            throw Error.connectivity
        }
        
        do {
            let items = try RemoteGalleryLoaderMapper.map(data, response: response)
            return items
        } catch {
            throw Error.invalidData
        }
    }
        
    // MARK: - Errors
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
}

enum RemoteGalleryLoaderMapper {
    
    private static let OK_200: Int = 200
    
    private struct Root: Decodable {
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
        
        var galleryItem: GalleryItem {
            GalleryItem(title: title, url: url, date: date, explanation: explanation, mediaType: mediaType, copyright: copyright, hdurl: hdurl, thumbnailUrl: thumbnailUrl)
        }
    }

    static func map(_ data: Data, response: HTTPURLResponse) throws -> [GalleryItem] {
        guard response.statusCode == OK_200 else {
            throw RemoteGalleryLoader.Error.invalidData
        }
        
        let items = try JSONDecoder().decode([Root].self, from: data)
        let galleryItems = items.map { $0.galleryItem }
        
        return galleryItems
    }
}
