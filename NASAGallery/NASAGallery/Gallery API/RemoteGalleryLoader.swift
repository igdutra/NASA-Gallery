//
//  RemoteGalleryLoader.swift
//  NASAGallery
//
//  Created by Ivo on 29/11/23.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL) async throws -> HTTPURLResponse
}

public class RemoteGalleryLoader {
    private let client: HTTPClient
    private let url: URL
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load() async throws {
        guard let _ = try? await client.get(from: url) else {
            throw Error.connectivity
        }
        
        // Note: For now, following TDD, if the client succeds, force deliver .invalidData
        throw Error.invalidData
    }
    
    // MARK: - Errors
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
}
