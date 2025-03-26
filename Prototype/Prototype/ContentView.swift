//
//  ContentView.swift
//  Prototype
//
//  Created by Ivo on 21/02/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        APODGalleryView()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

// MARK: - APOD

struct APODGalleryView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> APODGalleryViewController {
        return APODGalleryViewController()
    }
    
    func updateUIViewController(_ uiViewController: APODGalleryViewController, context: Context) {
        // No updates needed for now
    }
}

