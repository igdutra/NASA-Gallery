//
//  FreeFuncHelpers.swift
//  NASAGalleryTests
//
//  Created by Ivo on 01/12/23.
//

import Foundation
import NASAGallery

// MARK: - Free Funcs

func anyURL(_ string: String = "a-url.com") -> URL {
    // If the input is already a full URL (has a scheme), return it as-is.
    if let url = URL(string: string), url.scheme != nil {
        return url
    }
    // Otherwise, treat the input as a host and build an https URL.
    if let url = URL(string: "https://\(string)") {
        return url
    }
    var components = URLComponents()
    components.scheme = "https"
    components.host = string
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

func makeImages(title: String = "First Item") -> (model: [GalleryImage], data: Data) {
    let image1 = makeGalleryImageFixture(title: title)
    let image2 = makeGalleryImageFixture(urlString: "image1", explanation: "This is the second Item")
    let images = [image1, image2]
    let data = makeGalleryJSONData(images)
    
    return (images, data)
}

// MARK: - HTTPURLResponse

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

// MARK: - Date

extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
    
    static func from(_ dateString: String,
                     format: String = "yyyy-MM-dd",
                     timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!,
                     locale: Locale = Locale(identifier: "en_US_POSIX")) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = locale
        return dateFormatter.date(from: dateString)
    }
}

