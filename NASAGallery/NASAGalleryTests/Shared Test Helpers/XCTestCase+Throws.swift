//
//  XCTestCase+Throws.swift
//  NASAGalleryTests
//
//  Created by Ivo on 20/09/24.
//

import XCTest

extension XCTestCase {
    
    /// Example usage:
    /// ```
    /// func test_retrieve_onEmptyCache_deliversEmpty() async throws {
    ///     let sut = makeSUT()
    ///     let result = await expectNoThrowAsync(try await sut.retrieve())
    ///     XCTAssertNil(result, "Expected nil, got \(String(describing: result))")
    /// }
    /// ```
    func expectNoThrowAsync<AnyResult>(_ expression: @autoclosure () async throws -> AnyResult,
                                       _ message: @autoclosure () -> String = "",
                                       file: StaticString = #file, line: UInt = #line
    ) async throws-> AnyResult {
        do {
            return try await expression()
        } catch {
            XCTFail(message().isEmpty ? "Expected no error, but got: \(error)" : message(), file: file, line: line)
            throw error
        }
    }
    
    /// Example usage when expecting a specific error:
    /// ```swift
    /// func test_retrieve_onInvalidCache_throwsSpecificError() async {
    ///     let sut = makeSUT()
    ///     let error = await expectThrowAsync(try await sut.retrieve(), YourExpectedErrorType.self)
    ///     XCTAssertEqual(error as? YourExpectedErrorType, YourExpectedErrorType.someCase)
    /// }
    /// ```
    /// Example usage when you don't care about the error type:
    /// ```swift
    /// func test_retrieve_onInvalidCache_throwsAnyError() async {
    ///     let sut = makeSUT()
    ///     let error = await expectThrowAsync(try await sut.retrieve())
    ///     XCTAssertNotNil(error, "Expected an error, but no error was thrown")
    /// }
    /// ```
    @discardableResult
    func expectThrowAsync<AnyResult, ExpectedError: Error>(_ expression: @autoclosure () async throws -> AnyResult,
                                                           _ expectedError: ExpectedError.Type? = nil,
                                                           _ message: @autoclosure () -> String = "",
                                                           file: StaticString = #file, line: UInt = #line
    ) async -> Error? {
        do {
            _ = try await expression()
            XCTFail(message().isEmpty ? "Expected an error, but no error was thrown" : message(), file: file, line: line)
            return nil
        } catch let error as ExpectedError where expectedError != nil {
            return error
        } catch {
            if expectedError == nil {
                return error
            } else {
                XCTFail(message().isEmpty ? "Expected error of type \(String(describing: expectedError)), but got: \(error)" : message(), file: file, line: line)
                return nil
            }
        }
    }
}
