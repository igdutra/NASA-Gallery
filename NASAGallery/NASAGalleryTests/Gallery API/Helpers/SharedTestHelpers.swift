//
//  FreeFuncHelpers.swift
//  NASAGalleryTests
//
//  Created by Ivo on 01/12/23.
//

import Foundation
import NASAGallery

// MARK: - Fixtures

func makeGalleryItemFixture(title: String = "A Title",
                            urlString: String = "https://example.com/default.jpg",
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

// MARK: - Free Funcs

func anyURL(_ host: String = "a-url.com") -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = host
    return components.url!
}

func anyError() -> Error {
    struct AnyError: Error { }
    return AnyError()
}

func invalidJSON() -> Data {
    Data("Invalid JSON".utf8)
}

// MARK: - HTTPURLResponse

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
