// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(body)
public macro err() = #externalMacro(module: "ErrMacros", type: "Err")

struct TraceableError: Error {
	let line: UInt
	let file: String
	let function: String

	let root: Error
}

public extension Result {
	func to(_ err: inout Error?) -> (Success?) {
		switch self {
		case let .success(value):
			return value
		case let .failure(error):
			err = error
			return nil
		}
	}

	func err() -> Success? {
		fatalError("not implemented")
	}
}

//
public extension Result where Failure == Error {
	static func create(catching body: borrowing @escaping @Sendable () throws -> Success, __file: String = #fileID, __function: String = #function, __line: UInt = #line) -> Result<Success, Failure> {
		return Result { try body() }.mapError { err in
			return TraceableError(line: __line, file: __file, function: __function, root: err)
		}
	}

	static func create(catching body: borrowing @escaping @Sendable () async throws -> Success, __file: String = #fileID, __function: String = #function, __line: UInt = #line) async -> Result<Success, Failure> {
		do {
			let result = try await body()
			return .success(result)
		} catch {
			return .failure(TraceableError(line: __line, file: __file, function: __function, root: error))
		}
	}

	static func create(catching body: borrowing @escaping () async throws -> Success, __file: String = #fileID, __function: String = #function, __line: UInt = #line) async -> Result<Success, Failure> {
		do {
			let result = try await body()
			return .success(result)
		} catch {
			return .failure(TraceableError(line: __line, file: __file, function: __function, root: error))
		}
	}
}

//
// public extension Result where Failure == Error, Success == Void {
//	static func X(_ body: @escaping () throws -> Success, __file: String = #fileID, __function: String = #function, __line: UInt = #line) -> Result<Success, Failure> {
//		do {
//			try body()
//			return .success(())
//		} catch {
//			let err = x.error("caught", root: error, __file: __file, __function: __function, __line: __line)
//			return .failure(err)
//		}
//	}
//
//	static func X(_ body: @escaping @Sendable () async throws -> Success, __file: String = #fileID, __function: String = #function, __line: UInt = #line) async -> Result<Success, Failure> {
//		do {
//			try await body()
//			return .success(())
//		} catch {
//			let err = x.error("caught", root: error, __file: __file, __function: __function, __line: __line)
//			return .failure(err)
//		}
//	}
//
//	static func X(_ body: @escaping () async throws -> Success, __file: String = #fileID, __function: String = #function, __line: UInt = #line) async -> Result<Success, Failure> {
//		do {
//			try await body()
//			return .success(())
//		} catch {
//			let err = x.error("caught", root: error, __file: __file, __function: __function, __line: __line)
//			return .failure(err)
//		}
//	}
// }
