//
//  GalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 13/03/24.
//

import Foundation

public protocol GalleryStore {
    func deleteCachedGallery() throws
    func insertCache(gallery: [GalleryImage], timestamp: Date) throws
}
