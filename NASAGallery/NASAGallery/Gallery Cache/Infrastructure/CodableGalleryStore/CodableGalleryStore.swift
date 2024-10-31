//
//  CodableGalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 05/07/24.
//

import Foundation

public actor CodableGalleryStore: GalleryStore {
    private let storeURL: URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func retrieve() throws -> LocalGalleryCache? {
        guard FileManager.default.fileExists(atPath: storeURL.path()) else { return nil }
        
        let data = try Data(contentsOf: storeURL)
        let cache = try JSONDecoder().decode(Cache.self, from: data)
        return LocalGalleryCache(gallery: cache.localGallery, timestamp: cache.timestamp)
    }
    
    public func insert(_ cache: LocalGalleryCache) throws {
        let codableCache = Cache(gallery: cache.gallery.map(CodableLocalGalleryImage.init), timestamp: cache.timestamp)
        let data = try JSONEncoder().encode(codableCache)
        try data.write(to: storeURL)
    }
    
    public func delete() throws {
        guard FileManager.default.fileExists(atPath: storeURL.path()) else { return }
        try FileManager.default.removeItem(at: storeURL)
    }
    
    // MARK: - DTOs
    
    private struct Cache: Codable {
        let gallery: [CodableLocalGalleryImage]
        let timestamp: Date
        
        var localGallery: [LocalGalleryImage] {
            return gallery.map { $0.local }
        }
    }

    private struct CodableLocalGalleryImage: Codable {
        let title: String
        let url: URL
        let date: Date
        let explanation: String
        let mediaType: String
        
        let copyright: String?
        let hdurl: URL?
        let thumbnailUrl: URL?
        
        public init(local: LocalGalleryImage) {
            self.title = local.title
            self.url = local.url
            self.date = local.date
            self.explanation = local.explanation
            self.mediaType = local.mediaType
            self.copyright = local.copyright
            self.hdurl = local.hdurl
            self.thumbnailUrl = local.thumbnailUrl
        }
        
        var local: LocalGalleryImage {
            LocalGalleryImage(title: title, url: url, date: date, explanation: explanation, mediaType: mediaType, copyright: copyright, hdurl: hdurl, thumbnailUrl: thumbnailUrl)
        }
    }
}
