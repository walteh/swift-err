import Foundation
import Testing

@testable import Err

struct EmptyError: Error {}

func emptyError() -> Error {
	EmptyError()
}

// Test synchronous success case
@Test("Sync operator handles success case")
func testSyncOperatorSuccess() {
	var err = emptyError()
	let result = try { "success" }() !> err
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
	let result =
		try {
			throw TestError(message: "test error")
			return "success"
		}() !> err

	#expect(result == nil)
	#expect(err is TestError)
	#expect((err as? TestError)?.message == "test error")
}

// Test generic function version
@Test("Generic function version handles error case")
func testGenericFunctionVersion() throws {
	func divide(_ x: Int, by y: Int) throws -> Double {
		guard y != 0 else { throw DivisionError.divisionByZero }
		return Double(x) / Double(y)
	}

	enum DivisionError: Error {
		case divisionByZero
	}

	var err = emptyError()
	let result = try divide(10, by: 0) !> err

	#expect(result == nil)
	#expect(err is DivisionError)
}

// Test asynchronous success case
@Test("Async operator handles success case")
func testAsyncOperatorSuccess() async throws {
	var err = emptyError()
	let result = try await { "success" }() !> err
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
	let result =
		await
		(try await {
			throw TestError(message: "async test error")
			await Task.sleep(1_000_000_000)
			return "success"
		}()) !>> err

	#expect(result == nil)
	#expect(err is TestError)
	#expect((err as? TestError)?.message == "async test error")
}

// Test with real-world URL session example
@Test("URL session error handling")
func testURLSessionExample() async throws {
	var err = emptyError()
	let result =
		await (try await URLSession.shared.data(from: URL(string: "https://///status/404")!))
		!>> err

	#expect(result == nil)
	#expect(err is URLError)
}

@Test("URL session error handling")
func testURLSessionExample2() async throws {
	var err = emptyError()
	guard
		let result = await (try await URLSession.shared.data(from: URL(string: "https://///status/404")!))
			!>> .apply(&err, "test")
	else {
		return
	}

	#expect(result == nil)
	#expect(err is MError)
	#expect((err as? MError)?.message == "test")
	#expect((err as? MError)?.root is URLError)
}

@Test("URL session error handling")
func testURLSessionExample3() async throws {
	func someResult() -> Result<Data, Error> {
		.success(Data())
	}
	var err = emptyError()
	let res = someResult()
	guard let result = res !> err else {
		return
	}

	#expect(result == nil)
	#expect(err is EmptyError)
}

@Test("URL session error handling")
func testURLSessionExample4() async throws {
	func someAsyncResult() async -> Result<Data, Error> {
		.success(Data())
	}

	var err = emptyError()
	guard let result = await someAsyncResult() !> err else {
		return
	}

	#expect(result == Data())
	#expect(err is EmptyError)
}
