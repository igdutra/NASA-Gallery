//
//  SwiftDataGalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 14/11/24.
//

import Foundation
import SwiftData

@ModelActor
public final actor SwiftDataGalleryStore: GalleryStore {
    
    // MARK: - Retrieve
    
    public func retrieve() async throws -> LocalGalleryCache? {
        do {
            let fetchDescriptor = FetchDescriptor<SwiftDataStoredGalleryCache>()
            guard let storedCache = try modelContext.fetch(fetchDescriptor).first else {
                return nil
            }
            
            return SwiftDataMapper.toLocalCache(from: storedCache)
        } catch {
            modelContext.rollback()
            throw error
        }
    }
    
    // MARK: - Insert
    
    public func insert(_ cache: LocalGalleryCache) async throws {
        do {
            try deleteAllCachesFromMemory()
            
            let storedCache = SwiftDataMapper.toStoredCache(from: cache)
            
            modelContext.insert(storedCache)
            
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
    
    // MARK: - Delete
    
    public func delete() async throws {
        do {
            try deleteAllCachesFromMemory()
            
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
    
    // MARK: - Private Helpers
    
    /// Removes all cached gallery objects from the context, but does not call `save()`.
    /// - Throws: An error if the fetch or deletion fails.
    private func deleteAllCachesFromMemory() throws {
        let fetchDescriptor = FetchDescriptor<SwiftDataStoredGalleryCache>()
        let cache = try modelContext.fetch(fetchDescriptor).first
        cache.map(modelContext.delete)
    }
}
