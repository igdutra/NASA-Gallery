//
//  GalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 13/03/24.
//

import Foundation

// Note: why insertCache does not use LocalCache? can't conform to Equatable!
public protocol GalleryStore {
    func deleteCachedGallery() throws
    func insertCache(gallery: [LocalGalleryImage], timestamp: Date) throws
    func retrieve() throws -> LocalCache?
}
