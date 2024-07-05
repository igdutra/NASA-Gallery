//
//  GalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 13/03/24.
//

import Foundation

// Note: why insertCache does not use LocalCache? can't conform to Equatable!
// It can?
public protocol GalleryStore {
    func deleteCachedGallery() throws
    func insert(_ cache: LocalCache) throws
    func retrieve() throws -> LocalCache?
}
