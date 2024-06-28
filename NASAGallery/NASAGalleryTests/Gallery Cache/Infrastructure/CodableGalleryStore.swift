//
//  CodableGalleryStore.swift
//  NASAGallery
//
//  Created by Ivo on 27/06/24.
//

import XCTest

final class CodableGalleryStore { }
/* Author Notes on CodableGalleryStore
 Codable implementation of the GalleryStore
 
 This is not a use case to follow certain patters, but it is importatant to write a series of expectations, to help drive the unit tests!
 
## `GalleryStore` implementation Inbox

- Retrieve
    ✅ Empty cache returns empty
    ✅ Empty cache twice returns empty (no side-effects) (added in this lecture to be sure of side effects)
    ✅ Non-empty cache returns data
    - Non-empty cache twice returns same data (no side-effects)
    - Error returns error (if applicable, e.g., invalid data)
    - Error twice returns same error (if applicable, e.g., invalid data)
- Insert
    ✅ To empty cache stores data
    - To non-empty cache overrides previous data with new data
    - Error (if applicable, e.g., no write permission)
- Delete
    - Empty cache does nothing (cache stays empty and does not fail)
    - Non-empty cache leaves cache empty
    - Error (if applicable, e.g., no delete permission)
- Side-effects must run serially to avoid race-conditions

*/
//final class CodableFeedStoreTests: XCTestCase {
//    
//    func test_retrieve_onEmptyCache_deliversEmpty() throws {
//        XCTFail("Implement and add the template GLOBALLY to xcode so it does not get overriden at any version")
//    }
//}
