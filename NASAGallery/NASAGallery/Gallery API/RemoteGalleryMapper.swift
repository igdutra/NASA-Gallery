//
//  RemoteGalleryMapper.swift
//  NASAGallery
//
//  Created by Ivo on 13/12/23.
//

import Foundation

enum RemoteGalleryMapper {
    
    private static let OK_200: Int = 200
    
    public static func map(_ data: Data, response: HTTPURLResponse) throws -> [RemoteAPODItem] {
        guard response.statusCode == OK_200 else {
            throw RemoteGalleryLoader.Error.invalidData(underlying: URLError(.badServerResponse))
        }
        
        let decoder = JSONDecoder()        
        decoder.dateDecodingStrategy = .formatted(DateFormatter.remoteAPODDateFormatter)
        
        do {
            let items = try decoder.decode([RemoteAPODItem].self, from: data)
            return items
        } catch {
            throw RemoteGalleryLoader.Error.invalidData(underlying: error)
        }
    }
}

public extension DateFormatter {
    static let remoteAPODDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
