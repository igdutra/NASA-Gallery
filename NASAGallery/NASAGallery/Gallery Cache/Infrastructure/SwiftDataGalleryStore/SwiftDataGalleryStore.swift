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
            try await delete()
            
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
            let fetchDescriptor = FetchDescriptor<SwiftDataStoredGalleryCache>()
            let allCaches = try modelContext.fetch(fetchDescriptor)
            
            allCaches.forEach { modelContext.delete($0) }
            
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
