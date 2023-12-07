//
//  Fixtures.swift
//  NASAGalleryTests
//
//  Created by Ivo on 06/12/23.
//

import Foundation
import NASAGallery

// MARK: - GalleryItem

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

// MARK: - Data representation, ModelArray -> Data

func makeGalleryJSONData(_ items: [GalleryItem]) -> Data {
    // Created a root type, same as the RemoteGalleryMapper strategy, so that we avoid conforming GalleryItem directly to encodable
    // This replaces the JSONSerialization approach and the try!
    struct EncodableGalleryItem: Encodable {
        let galleryItem: GalleryItem

        enum CodingKeys: String, CodingKey {
            case date, explanation, title, url, hdurl
            case mediaType = "media_type"
            case thumbnailUrl = "thumbnail_url"
            case copyright
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(galleryItem.title, forKey: .title)
            try container.encode(galleryItem.url.absoluteString, forKey: .url)
            try container.encode(galleryItem.date, forKey: .date)
            try container.encode(galleryItem.explanation, forKey: .explanation)
            try container.encode(galleryItem.mediaType, forKey: .mediaType)
            try container.encodeIfPresent(galleryItem.copyright, forKey: .copyright)
            try container.encodeIfPresent(galleryItem.hdurl?.absoluteString, forKey: .hdurl)
            try container.encodeIfPresent(galleryItem.thumbnailUrl?.absoluteString, forKey: .thumbnailUrl)
        }
    }

    let encoder = JSONEncoder()
    do {
        let encodableItems = items.map { EncodableGalleryItem(galleryItem: $0) }
        let jsonData = try encoder.encode(encodableItems)
        return jsonData
    } catch {
        fatalError("Failed to encode GalleryItems: \(error)")
    }
}

/* NOTE Old compactMapValues
 
 Following chatGPT: using JSONEncoder is cleaner, safer, and more performant because leverages the compiler's understanding of your types to ensure everything is encoded correctly, avoiding the runtime overhead associated with dictionaries and Any types.
 Adding private to not impact outside this scope
 */
private extension GalleryItem {
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
