//
//  RemoteAPODLoader.swift
//  NASAGalleryTests
//
//  Created by Ivo on 20/11/23.
//

import XCTest

class RemoteAPODLoader {
    
}

protocol HTTPClient {
    func get(from url: URL)
}

class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    
    func get(from url: URL) {
        
    }
}


final class RemoteAPODLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let sut = RemoteAPODLoader()
        let client = HTTPClientSpy()
        
        XCTAssertNil(client.requestedURL)
    }
}
