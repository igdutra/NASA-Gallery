//
//  NSManagedObjectContext+Swizzling.swift
//  NASAGalleryTests
//
//  Created by Ivo on 04/11/24.
//

import CoreData.NSManagedObjectContext

extension NSManagedObjectContext {
    
    enum CoreDataTestError: Error {
        case forcedFetchFailure
        case forcedSaveFailure
        case swizzlingFailed
    }
    
    static func alwaysFailingFetchStub() -> Stub {
        Stub(
            originalSelector: #selector(NSManagedObjectContext.__execute(_:)),
            swizzledSelector: #selector(Stub.execute(_:))
        )
    }

    static func alwaysFailingSaveStub() -> Stub {
        Stub(
            originalSelector: #selector(NSManagedObjectContext.save),
            swizzledSelector: #selector(Stub.save)
        )
    }

    class Stub: NSObject {
        private let originalSelector: Selector
        private let swizzledSelector: Selector

        init(originalSelector: Selector, swizzledSelector: Selector) {
            self.originalSelector = originalSelector
            self.swizzledSelector = swizzledSelector
        }

        @objc func execute(_ request: Any) throws -> Any {
            throw CoreDataTestError.forcedFetchFailure
        }

        @objc func save() throws {
            throw CoreDataTestError.forcedSaveFailure
        }
        

        // Note: The original and swizzledSelector are plain "labels" to a method.
        // class_getInstanceMethod connects that label to the specific method in NSManagedObjectContext so we can swap it.
        func startIntercepting() throws {
            guard
                let originalMethod = class_getInstanceMethod(NSManagedObjectContext.self, originalSelector),
                let swizzledMethod = class_getInstanceMethod(Stub.self, swizzledSelector)
            else {
                throw CoreDataTestError.swizzlingFailed
            }

            method_exchangeImplementations(originalMethod, swizzledMethod)
        }

        deinit {
            if let originalMethod = class_getInstanceMethod(NSManagedObjectContext.self, originalSelector),
               let swizzledMethod = class_getInstanceMethod(Stub.self, swizzledSelector) {
                method_exchangeImplementations(swizzledMethod, originalMethod)
            }
        }
    }
}
