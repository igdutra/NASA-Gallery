//
//  Fixtures.swift
//  NASAGalleryTests
//
//  Created by Ivo on 06/12/23.
//

import Foundation
import NASAGallery

func makeGalleryItemFixture(title: String = "A Title",
                            urlString: String = "example.com",
                            date: String = "2023-01-01",
                            explanation: String = "A explanation",
                            mediaType: String = "image",
                            copyright: String? = nil,
                            hdurlString: String? = nil,
                            thumbnailUrlString: String? = nil
) -> GalleryItem {
    let url = anyURL(urlString)
    let hdurl = hdurlString != nil ? anyURL(hdurlString!) : nil
    let thumbnailUrl = thumbnailUrlString != nil ? anyURL(thumbnailUrlString!) : nil
    
    return GalleryItem(title: title,
                       url: url,
                       date: date,
                       explanation: explanation,
                       mediaType: mediaType,
                       copyright: copyright,
                       hdurl: hdurl,
                       thumbnailUrl: thumbnailUrl)
}

func makeGalleryJSON(_ items: [[String: Any]]) -> Data {
    do {
        return try JSONSerialization.data(withJSONObject: items)
    } catch {
        fatalError("Invalid JSON: \(error)")
    }
}

extension GalleryItem {
    func toJSON() -> [String: Any] {
        let json: [String: Any] = [
            "title": self.title,
            "url": self.url.absoluteString, // Can't serialize URLs
            "date": self.date,
            "explanation": self.explanation,
            "media_type": self.mediaType,
            "copyright": self.copyright,
            "hdurl": self.hdurl?.absoluteString,
            "thumbnail_url": self.thumbnailUrl?.absoluteString,
            "service_version": "v1", // Not used!
        ].compactMapValues { $0 }
        
        return json
    }
}
