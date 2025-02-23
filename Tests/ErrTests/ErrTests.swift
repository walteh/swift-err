import Testing
import _TestingInternals
@testable import Err
import Foundation


struct EmptyError: Error {
}

func emptyError() -> Error {
	return EmptyError()
}

// Test synchronous success case
@Test("Sync operator handles success case")
func testSyncOperatorSuccess() throws {
    var err = emptyError()
    let result = try { "success" }() ~> err
    #expect(result == "success")
    #expect(err is EmptyError)
}

// Test synchronous failure case
@Test("Sync operator handles error case")
func testSyncOperatorFailure() throws {
    struct TestError: Error {
        let message: String
    }

    var err = emptyError()
    let result = try {
        throw TestError(message: "test error")
        return "success"
    }() ~> err

    #expect(result == nil)
    #expect(err is TestError)
    #expect((err as? TestError)?.message == "test error")
}

// Test asynchronous success case
@Test("Async operator handles success case")
func testAsyncOperatorSuccess() async throws {
    var err = emptyError()
    let result = try await { "success" }() ~> err
    #expect(result == "success")
    #expect(err is EmptyError)
}

// Test asynchronous failure case
@Test("Async operator handles error case")
func testAsyncOperatorFailure() async throws {
    struct TestError: Error {
        let message: String
    }

    var err = emptyError()
    let result = try await {
        throw TestError(message: "async test error")
        return "success"
    }() ~> err

    #expect(result == nil)
    #expect(err is TestError)
    #expect((err as? TestError)?.message == "async test error")
}

// Test with real-world URL session example
// @Test("URL session error handling")
// func testURLSessionExample() async throws {
//     var err = emptyError()
//     let result = try await URLSession.shared.data(from: URL(string: "https://httpbin.org/status/404")!) ~> err

//     #expect(result == nil)
//     #expect(err is URLError)
// }



