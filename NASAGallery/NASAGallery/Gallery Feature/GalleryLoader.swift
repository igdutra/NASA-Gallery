//
//  GalleryLoader.swift
//  NASAGallery
//
//  Created by Ivo on 17/11/23.
//

import Foundation

public protocol GalleryLoader {
    func load() async throws -> [GalleryItem]
}
