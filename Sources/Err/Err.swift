// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(body)
public macro err() = #externalMacro(module: "ErrMacros", type: "Err")

@attached(body)
public macro err_traced() = #externalMacro(module: "ErrMacros", type: "ErrTraced")

public struct TraceableError: Error {
	public let line: UInt
	public let file: String
	public let function: String

	public let root: Error
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

	func ___to___traced(
		_ err: inout Error?,
		__file: String = #fileID,
		__function: String = #function,
		__line: UInt = #line
	) -> (Success?) {
		switch self {
		case let .success(value):
			return value
		case let .failure(error):
			err = TraceableError(line: __line, file: __file, function: __function, root: error)
			return nil
		}
	}
}

public extension Result where Failure == Error, Success: ~Copyable {
	static func ___err___create(
		catching body: () throws -> Success
	) -> Result<Success, Failure> {
		return Result { try body() }.mapError { err in
			return err
		}
	}

	static func ___err___create(
		catching body: () async throws -> Success
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
		tracing body: () throws -> Success,
		__file: String = #fileID,
		__function: String = #function,
		__line: UInt = #line
	) -> Result<Success, Failure> {
		return Result { try body() }.mapError { err in
			return TraceableError(line: __line, file: __file, function: __function, root: err)
		}
	}

	static func ___err___create(
		tracing body: () async throws -> Success,
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
