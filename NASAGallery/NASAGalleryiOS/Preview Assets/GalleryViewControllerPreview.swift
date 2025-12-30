//
//  GalleryViewControllerPreview.swift
//  NASAGalleryiOS
//
//  Created by Ivo on 24/09/25.
//

import Foundation
import UIKit
import SwiftUI // Preview Crashing although only using UIKit.
import NASAGallery

/* Author Note
 
 Simple file for visualization. Everything is self-contained and wrapped in if DEBUG, safe not not be shipped in prodution
 
*/

#if DEBUG
#Preview {
    let view = GalleryViewController(
        loader: GalleryLoaderPreview(),
        imageLoader: GalleryImageDataLoaderPreview()
    )
    view.collectionView.backgroundColor = .systemBackground
    return view
}

final class GalleryLoaderPreview: GalleryLoader {
    func load() async throws -> [GalleryImage] {
        [
            .preview(title: "Beautiful Red Nebula", url: URL(string: "https://example.com/red.png")!),
            .preview(title: "Ocean Blue Galaxy", url: URL(string: "https://example.com/blue.png")!),
            .preview(title: "Golden Sunset on Mars", url: URL(string: "https://example.com/gold.png")!),
            .preview(title: "Purple Aurora", url: URL(string: "https://example.com/purple.png")!),
            .preview(title: "This One Will Fail", url: URL(string: "https://example.com/fail.png")!)
        ]
    }
}

final class GalleryImageDataLoaderPreview: GalleryImageDataLoader {
    func loadImageData(from url: URL) -> GalleryImageDataLoaderTask {
        PreviewTask(url: url)
    }

    private final class PreviewTask: GalleryImageDataLoaderTask {
        private var task: Task<Data, Error>?

        init(url: URL) {
            task = Task {
                // Simulate network delay
                try await Task.sleep(for: .seconds(3))

                // Fail for specific URL to test retry button
                if url.absoluteString.contains("fail") {
                    throw NSError(domain: "Preview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Simulated failure"])
                }

                // Generate solid color based on URL
                let color: UIColor
                if url.absoluteString.contains("red") {
                    color = .systemRed
                } else if url.absoluteString.contains("blue") {
                    color = .systemBlue
                } else if url.absoluteString.contains("gold") {
                    color = .systemOrange
                } else if url.absoluteString.contains("purple") {
                    color = .systemPurple
                } else {
                    color = .systemGray
                }

                return createSolidColorImageData(color: color, size: CGSize(width: 800, height: 450))
            }
        }

        var value: Data {
            get async throws {
                guard let task = task else {
                    throw NSError(domain: "Preview", code: -2, userInfo: [NSLocalizedDescriptionKey: "Task was cancelled"])
                }
                return try await task.value
            }
        }

        func cancel() {
            task?.cancel()
            task = nil
        }

        private func createSolidColorImageData(color: UIColor, size: CGSize) -> Data {
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
            return image.pngData() ?? Data()
        }
    }
}
#endif

// MARK: - Fixtures

#if DEBUG
extension GalleryImage {
    static func preview(
        title: String = "Big Dipper over Pyramid Mountain",
        url: URL = URL(string: "https://apod.nasa.gov/apod/image/2312/BigDipperMt2_Cullen_960.jpg")!,
        date: Date = .now,
        explanation: String = "When did you first learn to...",
        mediaType: String = "image",
        copyright: String? = "\nSteve Cullen\n",
        hdurl: URL? = URL(string: "https://apod.nasa.gov/apod/image/2312/BigDipperMt2_Cullen_1365.jpg"),
        thumbnailUrl: URL? = nil
    ) -> GalleryImage {
        GalleryImage(
            title: title,
            url: url,
            date: date,
            explanation: explanation,
            mediaType: mediaType,
            copyright: copyright,
            hdurl: hdurl,
            thumbnailUrl: thumbnailUrl
        )
    }
}
#endif

