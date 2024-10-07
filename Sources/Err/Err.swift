// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(body)
public macro err() = #externalMacro(module: "ErrMacros", type: "Err")

@attached(body)
public macro err_traced() = #externalMacro(module: "ErrMacros", type: "ErrTraced")

struct TraceableError: Error {
	let line: UInt
	let file: String
	let function: String

	let root: Error
}

public extension Result {
	func ___to(_ err: inout Error?) -> (Success?) {
		switch self {
		case let .success(value):
			return value
		case let .failure(error):
			err = error
			return nil
		}
	}

	func ___to___traced(_ err: inout Error?) -> (Success?) {
		switch self {
		case let .success(value):
			return value
		case let .failure(error):
			err = TraceableError(line: #line, file: #file, function: #function, root: error)
			return nil
		}
	}

	func err() -> Success? {
		fatalError("not implemented")
	}
}

public extension Result where Failure == Error {
	static func ___err___create(
		catching body: borrowing @escaping @Sendable () throws -> Success
	) -> Result<Success, Failure> {
		return Result { try body() }.mapError { err in
			return err
		}
	}

	static func ___err___create(
		catching body: borrowing @escaping @Sendable () async throws -> Success
	) async -> Result<Success, Failure> {
		do {
			let result = try await body()
			return .success(result)
		} catch {
			return .failure(error)
		}
	}
}

public extension Result where Failure == Error {
	static func ___err___create(
		tracing body: borrowing @escaping @Sendable () throws -> Success,
		__file: String = #fileID,
		__function: String = #function,
		__line: UInt = #line
	) -> Result<Success, Failure> {
		return Result { try body() }.mapError { err in
			return TraceableError(line: __line, file: __file, function: __function, root: err)
		}
	}

	static func ___err___create(
		tracing body: borrowing @escaping @Sendable () async throws -> Success,
		__file: String = #fileID,
		__function: String = #function,
		__line: UInt = #line
	) async -> Result<Success, Failure> {
		do {
			let result = try await body()
			return .success(result)
		} catch {
			return .failure(
				TraceableError(line: __line, file: __file, function: __function, root: error)
			)
		}
	}
}
