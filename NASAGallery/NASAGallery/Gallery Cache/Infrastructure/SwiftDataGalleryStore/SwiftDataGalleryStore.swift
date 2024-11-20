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
    public func retrieve() async throws -> LocalGalleryCache? {
        nil
    }
    
    public func insert(_ cache: LocalGalleryCache) async throws {
    }
    
    public func delete() async throws {
    }
}

// Define a basic model
@Model
public final class User {
    @Attribute(.unique) public var id: UUID
    var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

// Define the model actor
@ModelActor
public final actor UserModelActor {
    // Insert operation
    public func insert(user: User) throws {
        modelContext.insert(user)
        try modelContext.save()
    }

    // Delete operation
    public func delete(user: User) throws {
        let allUsers = try fetchAllUsers()
        if allUsers.contains(user) {
            modelContext.delete(user)
            try modelContext.save()
        }
    }

    // Fetch all users
    public func fetchAllUsers() throws -> [User] {
        let fetchDescriptor = FetchDescriptor<User>()
        return try modelContext.fetch(fetchDescriptor)
    }
}
