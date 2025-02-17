//
//  SwiftDataGalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 14/11/24.
//

import Foundation
import SwiftData

// Author note: there's nothing to test with Reentrancy inside this actor, as there's no `await` keyword (thus no suspencion point) in any of the functions below.

@ModelActor
public final actor SwiftDataGalleryStore: GalleryStore {
    
    // MARK: - Retrieve
    
    public func retrieve() async throws -> LocalGalleryCache? {
        do {
            guard let storedCache = try fetchFirstCache() else {
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
    
    /// Fetches the first stored gallery cache from the context.
    /// - Returns: The first `SwiftDataStoredGalleryCache`, or `nil` if none exists.
    private func fetchFirstCache() throws -> SwiftDataStoredGalleryCache? {
        let fetchDescriptor = FetchDescriptor<SwiftDataStoredGalleryCache>()
        return try modelContext.fetch(fetchDescriptor).first
    }
    
    /// Removes all cached gallery objects from the context, but does not call `save()`.
    /// - Throws: An error if the fetch or deletion fails.
    private func deleteAllCachesFromMemory() throws {
        let cache = try fetchFirstCache()
        cache.map(modelContext.delete)
    }
}
