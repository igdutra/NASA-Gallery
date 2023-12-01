//
//  FreeFuncHelpers.swift
//  NASAGalleryTests
//
//  Created by Ivo on 01/12/23.
//

import Foundation

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

// MARK: - HTTPURLResponse

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
