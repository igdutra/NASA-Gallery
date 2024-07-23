//
//  GalleryCachePolicy.swift
//  NASAGallery
//
//  Created by Ivo on 29/03/24.
//

import Foundation

// Note: Stateless, it can be replaced by static or free functions.
public struct GalleryCachePolicy {
    private let maxCacheAgeInDays: Int = 2
    private let calendar = Calendar(identifier: .gregorian)
    
    public func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
