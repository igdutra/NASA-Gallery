//
//  XCTestCase+GalleryStoreSpecs.swift
//  NASAGalleryTests
//
//  Created by Ivo on 20/09/24.
//

import XCTest
import NASAGallery

extension GalleryStoreSpecs where Self: XCTestCase {
    
}

// MARK: - Helpers

extension GalleryStoreSpecs where Self: XCTestCase {
    
    func expect(_ sut: GalleryStore,
                toRetrieve expectedResult: LocalCache?,
                _ comment: String,
                file: StaticString = #filePath, line: UInt = #line) async {
        do {
            let result = try await sut.retrieve()
            XCTAssertEqual(result, expectedResult, comment, file: file, line: line)
        } catch {
            XCTFail("Expected: \(comment), got \(error) instead")
        }
    }
    
    func expect(_ sut: GalleryStore,
                toRetrieveTwice expectedResult: LocalCache?,
                _ comment: String,
                file: StaticString = #filePath, line: UInt = #line) async {
        do {
            let result1 = try await sut.retrieve()
            let result2 = try await sut.retrieve()
            XCTAssertEqual(result1, expectedResult, comment, file: file, line: line)
            XCTAssertEqual(result2, expectedResult, comment, file: file, line: line)
        } catch {
            XCTFail("Expected: \(comment), got \(error) instead")
        }
    }
    
    func insert(_ expectedCache: LocalCache, to sut: GalleryStore) async {
        try? await expectNoThrowAsync(try await sut.insert(expectedCache))
    }

}
