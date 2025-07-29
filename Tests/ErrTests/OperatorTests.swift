import Foundation
import Testing

@testable import Err

// Test synchronous success case
@Test("Sync operator handles success case")
func testSyncOperatorSuccess() {
	var err: Error = .nil
	let result = try { "success" }() !> err
	#expect(result == "success")
	#expect(err is Error.Nil)
}

// Test synchronous failure case
@Test("Sync operator handles error case")
func testSyncOperatorFailure() throws {
	struct TestError: Error {
		let message: String
	}

	var err: Error = .nil
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

	var err: Error = .nil
	let result = try divide(10, by: 0) !> err

	#expect(result == nil)
	#expect(err is DivisionError)
}

// Test asynchronous success case
@Test("Async operator handles success case")
func testAsyncOperatorSuccess() async throws {
	var err: Error = .nil
	let result = try await { "success" }() !> err
	#expect(result == "success")
	#expect(err is Error.Nil)
}

// Test asynchronous failure case
@Test("Async operator handles error case")
func testAsyncOperatorFailure() async throws {
	struct TestError: Error {
		let message: String
	}

	var err: Error = .nil
	let result =
		await
		(try await {
			throw TestError(message: "async test error")
			try await Task.sleep(nanoseconds: 1_000_000_000)
			return "success"
		}()) !>> err

	#expect(result == nil)
	#expect(err is TestError)
	#expect((err as? TestError)?.message == "async test error")
}

// Test with real-world URL session example
@Test("URL session error handling")
func testURLSessionExample() async throws {
	var err: Error = .nil
	let result =
		await (try await URLSession.shared.data(from: URL(string: "https://///status/404")!))
		!>> .ctx(&err, "test")

	#expect(result == nil)
	#expect(err is CallerError)
	#expect(err.cause(as: URLError.self) != nil)
}

@Test("URL session error handling")
func testURLSessionExample2() async throws {
	var err: Error = .nil
	guard
		let result = await (try await URLSession.shared.data(from: URL(string: "https://///status/404")!))
			!>> .ctx(&err, "test")
	else {
		return
	}

	#expect(result == nil)
	#expect(err is CallerError)
	#expect((err as? CallerError)?.message == "test")
	#expect((err as? CallerError)?.cause is URLError)
}

@Test("URL session error handling")
func testURLSessionExample3() async throws {
	func someResult() -> Result<Data, Error> {
		.success(Data())
	}
	var err: Error = .nil
	let res = someResult()
	guard let result = res !> .ctx(&err, "test") else {

		if let err = err.cause(as: URLError.self) {
			print(err)
			// handle network error
		} else {
			// handle other error
		}

		return
	}

	#expect(result != nil)
	#expect(err is Error.Nil)
}

@Test("URL session error handling")
func testURLSessionExample4() async throws {
	func someAsyncResult() async -> Result<Data, Error> {
		.success(Data())
	}

	var err: Error = .nil
	guard let result = await someAsyncResult() !> err else {
		return
	}

	#expect(result == Data())
	#expect(err is Error.Nil)
}
