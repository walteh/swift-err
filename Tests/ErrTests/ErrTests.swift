import XCTest

@testable import Err

func dummyAsyncFunc<T>(_ arg: consuming T, _ err: consuming Error?) async throws -> T {
	if let err = err {
		throw err
	}
	return arg
}

final class ErrTests: XCTestCase {
	func testTo() {
		var error: Error?

		// Test success case
		let successResult: Result<Int, Error> = .success(42)
		let successValue = successResult.___to(&error)
		XCTAssertEqual(successValue, 42)
		XCTAssertNil(error)

		// Test failure case
		let failureResult: Result<Int, Error> = .failure(
			NSError(domain: "Test", code: 1, userInfo: nil)
		)
		let failureValue = failureResult.___to(&error)
		XCTAssertNil(failureValue)
		XCTAssertNotNil(error)
	}

	func testToTraced() {
		var error: Error?

		// Test success case
		let successResult: Result<String, Error> = .success("Hello")
		let successValue = successResult.___to___traced(&error)
		XCTAssertEqual(successValue, "Hello")
		XCTAssertNil(error)

		// Test failure case
		let failureResult: Result<String, Error> = .failure(
			NSError(domain: "Test", code: 2, userInfo: nil)
		)
		let failureValue = failureResult.___to___traced(&error)
		XCTAssertNil(failureValue)
		XCTAssertNotNil(error)
		XCTAssertTrue(error is CError)
		if let TError = error as? CError {
			XCTAssertEqual(TError.caller.file, #file)
			XCTAssertEqual(TError.caller.function, #function)
			XCTAssertEqual(TError.caller.line, "\(#line - 7)")  // Adjust this based on the actual line number
		}
	}

	func testErrCreate() {
		// Test success case
		let successResult = Result<Int, Error>.___err___create {
			return 42
		}
		XCTAssertEqual(try successResult.get(), 42)

		// Test failure case
		let failureResult = Result<Int, Error>.___err___create {
			throw NSError(domain: "Test", code: 3, userInfo: nil)
		}
		XCTAssertThrowsError(try failureResult.get()) { error in
			XCTAssertEqual((error as NSError).code, 3)
		}
	}

	func testAsyncErrCreate() async {
		// Test success case
		let successResult = await Result<String, Error>.___err___create {
			return try await dummyAsyncFunc("Async Success", nil)
		}
		XCTAssertEqual(try successResult.get(), "Async Success")

		// Test failure case
		let failureResult = await Result<String, Error>.___err___create {
			return try await dummyAsyncFunc(
				"Async Failure",
				NSError(domain: "Test", code: 4, userInfo: nil)
			)
		}
		XCTAssertThrowsError(try failureResult.get()) { error in
			XCTAssertEqual((error as NSError).code, 4)
		}
	}

	func testErrCreateTracing() {
		// Test success case
		let successResult = Result<Double, Error>.___err___create(tracing: {
			return 3.14
		})
		XCTAssertEqual(try successResult.get(), 3.14)

		// Test failure case
		let failureResult = Result<Double, Error>.___err___create(tracing: {
			throw NSError(domain: "Test", code: 5, userInfo: nil)
		})
		XCTAssertThrowsError(try failureResult.get()) { error in
			XCTAssertTrue(error is CError)
			if let TError = error as? CError {
				XCTAssertEqual(TError.caller.file, #fileID)
				XCTAssertEqual(TError.caller.function, #function)
				XCTAssertEqual((TError.root as NSError).code, 5)
			}
		}
	}

	func testAsyncErrCreateTracing() async {
		// Test success case
		let successResult = await Result<[Int], Error>.___err___create(tracing: {
			return try await dummyAsyncFunc([1, 2, 3], nil)
		})
		XCTAssertEqual(try successResult.get(), [1, 2, 3])

		// Test failure case
		let failureResult = await Result<[Int], Error>.___err___create(tracing: {
			return try await dummyAsyncFunc(
				[4, 5, 6],
				NSError(domain: "Test", code: 6, userInfo: nil)
			)
		})
		XCTAssertThrowsError(try failureResult.get()) { error in
			XCTAssertTrue(error is CError)
			if let t = error as? CError {
				XCTAssertEqual(t.caller.file, #fileID)
				XCTAssertEqual(t.caller.function, #function)
				XCTAssertEqual((t.root as NSError).code, 6)
			}
		}
	}
}
