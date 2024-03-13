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
            throw RemoteGalleryLoader.Error.invalidData
        }
        
        let items = try JSONDecoder().decode([RemoteAPODItem].self, from: data)
      
        return items
    }
}
