//
//  SwiftDataGalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 14/11/24.
//

import Foundation
import SwiftData

// Define a basic model
@Model
final class User {
    @Attribute(.unique) var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

// Define the model actor
@ModelActor
final actor UserModelActor {
    // Insert operation
    func insert(user: User) throws {
        modelContext.insert(user)
        try modelContext.save()
    }

    // Delete operation
    func delete(user: User) throws {
        let allUsers = try fetchAllUsers()
        if allUsers.contains(user) {
            modelContext.delete(user)
            try modelContext.save()
        }
    }

    // Fetch all users
    func fetchAllUsers() throws -> [User] {
        let fetchDescriptor = FetchDescriptor<User>()
        return try modelContext.fetch(fetchDescriptor)
    }
}

// MARK: - Example usage

public struct ModelActorExample {
    public init () {}
    public static func main() async {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: User.self, configurations: config)
            
            // Initialize the UserModelActor
            let userActor = UserModelActor(modelContainer: container)
            
            // Create a sample user
            let newUser = User(name: "John Doe")
            
            // Insert the user into the actor
            try await userActor.insert(user: newUser)
            
            // Fetch and print all users
            let users = try await userActor.fetchAllUsers()
            print(users)
            
            // Delete the user
            try await userActor.delete(user: newUser)
            
            // Fetch and print all users again (should be empty)
            let updatedUsers = try await userActor.fetchAllUsers()
            print(updatedUsers)
        } catch {
            print("An error occurred: \(error)")
        }
    }
}
