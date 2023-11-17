//
//  APODLoader.swift
//  NASAGallery
//
//  Created by Ivo on 17/11/23.
//

import Foundation

protocol APODLoader {
    func load() async throws -> [APODItem]
}
