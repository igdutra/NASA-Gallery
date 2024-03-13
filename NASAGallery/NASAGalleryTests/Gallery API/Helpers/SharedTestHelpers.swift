//
//  FreeFuncHelpers.swift
//  NASAGalleryTests
//
//  Created by Ivo on 01/12/23.
//

import Foundation
import NASAGallery

// MARK: - Free Funcs

func anyURL(_ host: String = "a-url.com") -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = host
    return components.url ?? URL(string: "https://default-url.com")!
}

struct AnyError: Error, Equatable {
    let message: String
    init(message: String = .init()) {
        self.message = message
    }
}

func anyErrorErased(_ message: String = .init()) -> Error {
    return AnyError(message: message)
}

func invalidJSON() -> Data {
    Data("Invalid JSON".utf8)
}

func anyData() -> Data {
    return Data("any data".utf8)
}

// MARK: - Models

func makeItems() -> (model: [GalleryItem], data: Data) {
    let item1 = makeGalleryItemFixture(title: "First Item")
    let item2 = makeGalleryItemFixture(urlString: "image1", explanation: "This is the second Item")
    let items = [item1, item2]
    let data = makeGalleryJSONData(items)
    
    return (items, data)
}

// MARK: - HTTPURLResponse

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
