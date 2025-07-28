import Foundation

precedencegroup ErrorHandlingPrecedence {
	associativity: left
	higherThan: AssignmentPrecedence
	lowerThan: TernaryPrecedence
}

precedencegroup LogPrecedence {
	associativity: left
	higherThan: ErrorHandlingPrecedence
}

infix operator !> : ErrorHandlingPrecedence
infix operator !>> : ErrorHandlingPrecedence

@inline(__always)
public func !> <T>(value: @autoclosure @escaping () throws -> T, err: inout Error) -> T? {
	do {
		return try value()
	} catch let errd {
		err = errd
		return nil
	}
}

@inline(__always)
public func !>> <T>(
	value: @Sendable @autoclosure @escaping () async throws -> T,
	err: inout Error
) async -> T? {
	do {
		return try await value()
	} catch let errd {
		err = errd
		return nil
	}
}

public struct ContextErrorPointer {
	var err_ptr: UnsafeMutablePointer<Error>
	var message: String
	var file: String
	var line: UInt
	var function: String

	public init(
		_ err_ptr: inout Error,
		_ message: String,
		_ file: String = #file,
		_ line: UInt = #line,
		_ function: String = #function
	) {
		self.err_ptr = withUnsafeMutablePointer(to: &err_ptr) { $0 }
		self.message = message
		self.file = file
		self.line = line
		self.function = function
	}

	public static func ctx(
		_ err_ptr: inout Error,
		_ message: String,
		_ file: String = #file,
		_ line: UInt = #line,
		_ function: String = #function
	) -> ContextErrorPointer {
		ContextErrorPointer(&err_ptr, message, file, line, function)
	}
}

@inline(__always)
public func !> <T>(value: @autoclosure @escaping () throws -> T, _ err: ContextErrorPointer) -> T? {
	do {
		return try value()
	} catch let errd {
		err.err_ptr.pointee = ContextError(
			err.message,
			cause: errd,
			__file: err.file,
			__function: err.function,
			__line: err.line
		)
		return nil
	}
}

@inline(__always)
public func !>> <T>(
	value: @Sendable @autoclosure @escaping () async throws -> T,
	_ err: ContextErrorPointer
) async -> T? {
	do {
		return try await value()
	} catch let errd {
		err.err_ptr.pointee = ContextError(
			err.message,
			cause: errd,
			__file: err.file,
			__function: err.function,
			__line: err.line
		)
		return nil
	}
}

extension Result {
	@inline(__always)
	public static func !> (result: Result, err: inout Error) -> Success? {
		try result.get() !> err
	}

	@inline(__always)
	public static func !> (result: Result, err: ContextErrorPointer) -> Success? {
		try result.get() !> err
	}
}

extension Result where Failure == Error, Success: ~Copyable {
	@inline(__always)
	public init(
		catching body: () throws -> Success
	) {
		do {
			let result = try body()
			self = .success(result)
		} catch {
			self = .failure(error)
		}
	}

	@inline(__always)
	public init(
		catching body: @Sendable @escaping () async throws -> Success
	) async {
		do {
			let result = try await body()
			self = .success(result)
		} catch {
			self = .failure(error)
		}
	}
}

// @inline(__always)
// prefix func ~ <T, D>(_ value: T) -> D? where T: Error, D: Error {
// 	return value.caused(by: D.self)
// }

// @inline(__always)
// prefix func ~ <T, D>(_ value: T) -> D? {
// 	return value is D ? value as? D : nil
// }
