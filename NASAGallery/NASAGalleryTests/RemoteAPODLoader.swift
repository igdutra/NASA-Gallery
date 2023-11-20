//
//  RemoteAPODLoader.swift
//  NASAGalleryTests
//
//  Created by Ivo on 20/11/23.
//

import XCTest

class RemoteAPODLoader {
    let client: HTTPClient
    let url: URL
    
    init(url: URL = URL(string: "a-url.com")!, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load() {
        client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    
    func get(from url: URL) {
        requestedURL = url
    }
}


final class RemoteAPODLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        let sut = RemoteAPODLoader(client: client)
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "b-url.com")!
        let client = HTTPClientSpy()
        let sut = RemoteAPODLoader(url: url, client: client)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURL, url)
    }
}
