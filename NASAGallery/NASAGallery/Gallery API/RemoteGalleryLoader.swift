//
//  RemoteGalleryLoader.swift
//  NASAGallery
//
//  Created by Ivo on 29/11/23.
//

import Foundation

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
            let items = try RemoteGalleryMapper.map(data, response: response)
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
