//
//  URLSessionHTTPClient.swift
//  NASAGallery
//
//  Created by Ivo on 21/12/23.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func getData(from url: URL) async throws -> (data: Data, response: HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.cannotParseResponse)
            }
            
            return (data: data, response: httpResponse)
        } catch {
            throw error
        }
    }
}
