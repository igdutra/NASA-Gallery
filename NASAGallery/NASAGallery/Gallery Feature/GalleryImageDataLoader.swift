//
//  GalleryImageDataLoader.swift
//  NASAGallery
//
//  Created by Claude on 16/12/25.
//

import Foundation

public protocol GalleryImageDataLoaderTask {
    func cancel()
    var value: Data { get async throws }
}

public protocol GalleryImageDataLoader {
    func loadImageData(from url: URL) -> GalleryImageDataLoaderTask
}
