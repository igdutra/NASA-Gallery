//
//  NASAGalleryEndToEndTests.swift
//  NASAGalleryEndToEndTests
//
//  Created by Ivo on 23/12/23.
//

import XCTest
import NASAGallery

final class NASAGalleryEndToEndTests: XCTestCase {
    
    func test_remoteGalleryLoader_loadPreciseItems() async throws {
        let url = getAPODURL()
        let client = URLSessionHTTPClient()
        let loader = RemoteGalleryLoader(url: url, client: client)
        // Note: expectation is used for timeout purposes
        let expectation = XCTestExpectation(description: "Wait for load to complete")
        
        do {
            let items = try await loader.load()
            
            let firstItem = try XCTUnwrap(items.first)
            let secondItem = try XCTUnwrap(items[1])
            
            assert(firstItem, matches: expectedItemOn10Dec2023())
            assert(secondItem, matches: expectedItemOn11Dec2023())
            
            expectation.fulfill()
        } catch {
            XCTFail("Test failed with error: \(error)")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
}

// MARK: - Helpers

private extension NASAGalleryEndToEndTests {
    
    func assert(_ item1: GalleryItem, matches item2: GalleryItem, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(item1.title, item2.title, "Expected title to match", file: file, line: line)
        XCTAssertEqual(item1.url, item2.url, "Expected URL to match", file: file, line: line)
        XCTAssertEqual(item1.date, item2.date, "Expected date to match", file: file, line: line)
        XCTAssertEqual(item1.explanation, item2.explanation, "Expected explanation to match", file: file, line: line)
        XCTAssertEqual(item1.mediaType, item2.mediaType, "Expected mediaType to match", file: file, line: line)
        
        // Optional fields
        XCTAssertEqual(item1.copyright, item2.copyright, "Expected copyright to match", file: file, line: line)
        XCTAssertEqual(item1.hdurl, item2.hdurl, "Expected HD URL to match", file: file, line: line)
        XCTAssertEqual(item1.thumbnailUrl, item2.thumbnailUrl, "Expected thumbnail URL to match", file: file, line: line)
    }
    
    // TODO: Create new form to abstract that
    // https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY&date=2023-12-23
    func getAPODURL() -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.nasa.gov"
        components.path = "/planetary/apod"
        
        let queryItems = [
            URLQueryItem(name: "api_key", value: "DEMO_KEY"),
            URLQueryItem(name: "start_date", value: "2023-12-10"),
            URLQueryItem(name: "end_date", value: "2023-12-11"),
            URLQueryItem(name: "thumbs", value: "true")
        ]
        components.queryItems = queryItems
        
        return components.url!
    }
    
    func expectedItemOn10Dec2023() -> GalleryItem {
        GalleryItem(title: "Big Dipper over Pyramid Mountain",
                    url: URL(string: "https://apod.nasa.gov/apod/image/2312/BigDipperMt2_Cullen_960.jpg")!,
                    date: "2023-12-10",
                    explanation: "When did you first learn to identify this group of stars? Although they are familiar to many people around the world, different cultures have associated this asterism with different icons and folklore. Known in the USA as the Big Dipper, the stars are part of a constellation designated by the International Astronomical Union in 1922 as the Great Bear (Ursa Major).  The recognized star names of these stars are (left to right) Alkaid, Mizar/Alcor, Alioth, Megrez, Phecda, Merak, and Dubhe.  Of course, stars in any given constellation are unlikely to be physically related. But surprisingly, most of the Big Dipper stars do seem to be headed in the same direction as they plough through space, a property they share with other stars spread out over an even larger area across the sky.  Their measured common motion suggests that they all belong to a loose, nearby star cluster, thought to be on average only about 75 light-years away and up to 30 light-years across. The cluster is more properly known as the Ursa Major Moving Group. The featured image captured the iconic stars in 2017 above Pyramid Mountain in Alberta, Canada.   Night Sky Network webinar: APOD editor to review coolest space images of 2023",
                    mediaType: "image",
                    copyright: "\nSteve Cullen\n",
                    hdurl: URL(string: "https://apod.nasa.gov/apod/image/2312/BigDipperMt2_Cullen_1365.jpg"),
                    thumbnailUrl: nil)
    }

    func expectedItemOn11Dec2023() -> GalleryItem {
        return GalleryItem(
            title: "Solar Minimum versus Solar Maximum",
            url: URL(string: "https://www.youtube.com/embed/JqH0diwqcUM?rel=0")!,
            date: "2023-12-11",
            explanation: "The surface of our Sun is constantly changing.  Some years it is quiet, showing relatively few sunspots and active regions. Other years it is churning, showing many sunspots and throwing frequent Coronal Mass Ejections (CMEs) and flares. Reacting to magnetism, our Sun's surface goes through periods of relative calm, called Solar Minimum and relative unrest, called Solar Maximum, every 11 years. The featured video shows on the left a month in late 2019 when the Sun was near Solar Minimum, while on the right a month in 2014 when near Solar Maximum.  The video was taken by NASA's Solar Dynamic Observatory in far ultraviolet light. Our Sun is progressing again toward Solar Maximum in 2025, but displaying even now a surface with a surprisingly high amount of activity.   Night Sky Network webinar: APOD editor to review coolest space images of 2023",
            mediaType: "video",
            copyright: nil, // Copyright is not provided
            hdurl: nil, // HD URL is not applicable for a video type
            thumbnailUrl: URL(string: "https://img.youtube.com/vi/JqH0diwqcUM/0.jpg")
        )
    }
}
