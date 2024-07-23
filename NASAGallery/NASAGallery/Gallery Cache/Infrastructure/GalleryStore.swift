//
//  GalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 13/03/24.
//

import Foundation

public protocol GalleryStore {
    func deleteCachedGallery() async throws
    func insert(_ cache: LocalCache) throws
    func retrieve() throws -> LocalCache?
}
