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
    var view = UIViewController()
    view.view.backgroundColor = .red
    return view
}

final class GalleryLoaderPreview: GalleryLoader {
    func load() async throws -> [NASAGallery.GalleryImage] {
        [.fixture()]
    }
}
#endif

// MARK: - Fixtures

#if DEBUG
extension GalleryImage {
    static func fixture(
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

