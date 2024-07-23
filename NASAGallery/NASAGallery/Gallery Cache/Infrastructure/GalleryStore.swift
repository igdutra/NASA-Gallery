//
//  GalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 13/03/24.
//

import Foundation

public protocol GalleryStore {
    func delete() async throws
    func insert(_ cache: LocalCache) async throws
    func retrieve() throws -> LocalCache?
}
