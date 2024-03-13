//
//  RemoteGalleryLoader.swift
//  NASAGallery
//
//  Created by Ivo on 29/11/23.
//

import Foundation

public final class RemoteGalleryLoader: GalleryLoader {
    private let client: HTTPClient
    private let url: URL
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load() async throws -> [GalleryImage] {
        guard let (data, response) = try? await client.getData(from: url) else {
            throw Error.connectivity
        }
        
        do {
            let items = try RemoteGalleryMapper.map(data, response: response)
            return items.toModels()
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

// MARK: - Array Extension
// Moving the mapping logic from RemoteAPODItem -> GalleryImage to RemoteGalleryLoader reduces the pointing arrows to GalleryImage!
private extension Array where Element == RemoteAPODItem {
    func toModels() -> [GalleryImage] {
        return map { GalleryImage(title: $0.title, url: $0.url, date: $0.date, explanation: $0.explanation, mediaType: $0.mediaType, copyright: $0.copyright, hdurl: $0.hdurl, thumbnailUrl: $0.thumbnailUrl) }
    }
}
