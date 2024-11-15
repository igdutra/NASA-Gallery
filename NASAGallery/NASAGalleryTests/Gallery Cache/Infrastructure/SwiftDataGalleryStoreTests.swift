//
//  SwiftDataGalleryStoreTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 14/11/24.
//

import XCTest
import NASAGallery

final class SwiftDataGalleryStoreTests: XCTestCase {

    func test() async {
        let test = ModelActorExample()
       await  ModelActorExample.main()
        print("\n\n\n\n FINISHED")
    }
}
