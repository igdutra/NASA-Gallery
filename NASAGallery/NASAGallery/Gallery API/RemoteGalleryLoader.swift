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
        
        if response.statusCode == 200,
           let _ = try? JSONSerialization.jsonObject(with: data) {
            return []
        } else {
            throw Error.invalidData
        }
    }
    
    // MARK: - Errors
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
}
