//
//  HTTPClient.swift
//  NASAGallery
//
//  Created by Ivo on 13/12/23.
//

import Foundation

public protocol HTTPClient {
    func getData(from url: URL) async throws -> (data: Data, response: HTTPURLResponse)
}
