//
//  RemoteGalleryLoader.swift
//  NASAGallery
//
//  Created by Ivo on 29/11/23.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL) async throws
}

public class RemoteGalleryLoader {
    private let client: HTTPClient
    private let url: URL
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load() async throws {
        do {
            try await client.get(from: url)
        } catch {
            throw Error.connectivity
        }
    }
    
    // MARK: - Errors
    
    public enum Error: Swift.Error {
        case connectivity
    }
}
