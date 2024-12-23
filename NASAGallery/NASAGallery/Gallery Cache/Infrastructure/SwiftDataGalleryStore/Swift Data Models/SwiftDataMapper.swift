//
//  SwiftDataMapper.swift
//  NASAGallery
//
//  Created by Ivo on 23/12/24.
//

import Foundation

enum SwiftDataMapper {
    
    // MARK: - Stored to Local
    
    static func toLocalCache(from storedCache: SwiftDataStoredGalleryCache) -> LocalGalleryCache {
        let images = toLocalImages(from: storedCache)
        return LocalGalleryCache(gallery: images, timestamp: storedCache.timestamp)
    }
    
    static func toLocalImages(from storedCache: SwiftDataStoredGalleryCache) -> [LocalGalleryImage] {
        // Sort by sortIndex to maintain ordering
        storedCache.gallery
            .sorted { $0.sortIndex < $1.sortIndex }
            .map(toLocalImage(from:))
    }
    
    static func toLocalImage(from storedImage: SwiftDataStoredGalleryImage) -> LocalGalleryImage {
        LocalGalleryImage(title: storedImage.title,
                          url: storedImage.url,
                          date: storedImage.date,
                          explanation: storedImage.explanation,
                          mediaType: storedImage.mediaType,
                          copyright: storedImage.copyright,
                          hdurl: storedImage.hdurl,
                          thumbnailUrl: storedImage.thumbnailUrl)
    }
    
    // MARK: - Local to Stored
    
    /// Creates a new `SwiftDataStoredGalleryCache` including all images and returns it.
    /// - Parameter localCache: The local cache model you wish to convert.
    /// - Returns: A newly constructed `SwiftDataStoredGalleryCache` instance containing all images.
    static func toStoredCache(from localCache: LocalGalleryCache) -> SwiftDataStoredGalleryCache {
        let storedCache = SwiftDataStoredGalleryCache(timestamp: localCache.timestamp)
        
        let storedImages = toStoredImages(from: localCache.gallery, cache: storedCache)
        storedCache.gallery = storedImages
        
        return storedCache
    }
    
    /// Converts an array of `LocalGalleryImage` into `SwiftDataStoredGalleryImage`
    /// and returns the resulting array of stored images.
    /// - Parameters:
    ///   - localImages: The list of `LocalGalleryImage` you wish to convert.
    ///   - cache: The `SwiftDataStoredGalleryCache` the images belong to.
    static func toStoredImages(from localImages: [LocalGalleryImage],
                               cache: SwiftDataStoredGalleryCache) -> [SwiftDataStoredGalleryImage] {
        localImages.enumerated().map { index, localImage in
            toStoredImage(index: index, from: localImage, cache: cache)
        }
    }
    
    /// Converts a single `LocalGalleryImage` to `SwiftDataStoredGalleryImage`.
    /// - Parameters:
    ///   - index: The position of this image in the array (used as sortIndex).
    ///   - localImage: The `LocalGalleryImage` to be transformed.
    ///   - cache: The parent cache that owns the images.
    static func toStoredImage(index: Int,
                              from localImage: LocalGalleryImage,
                              cache: SwiftDataStoredGalleryCache) -> SwiftDataStoredGalleryImage {
        SwiftDataStoredGalleryImage(sortIndex: index,
                                    title: localImage.title,
                                    url: localImage.url,
                                    date: localImage.date,
                                    explanation: localImage.explanation,
                                    mediaType: localImage.mediaType,
                                    copyright: localImage.copyright,
                                    hdurl: localImage.hdurl,
                                    thumbnailUrl: localImage.thumbnailUrl,
                                    imageData: nil,
                                    cache: cache)
    }
}
