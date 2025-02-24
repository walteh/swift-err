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

infix operator !? : ErrorHandlingPrecedence
infix operator !> : ErrorHandlingPrecedence
infix operator !>> : ErrorHandlingPrecedence

@inline(__always)
func !> <T>(value: @autoclosure @escaping () throws -> T, err: inout Error) -> T? {
	do {
		return try value()
	} catch let errd {
		err = errd
		return nil
	}
}

@inline(__always)
func !>> <T>(value: @Sendable @autoclosure @escaping () async throws -> T, err: inout Error) async -> T? {
	do {
		return try await value()
	} catch let errd {
		err = errd
		return nil
	}
}

struct ErrInfo {
	var err_ptr: UnsafeMutablePointer<Error>
	var message: String
	var file: String
	var line: UInt
	var function: String

	init(_ err_ptr: inout Error, _ message: String, _ file: String = #file, _ line: UInt = #line, _ function: String = #function) {
		self.err_ptr = withUnsafeMutablePointer(to: &err_ptr) { $0 }
		self.message = message
		self.file = file
		self.line = line
		self.function = function
	}

	static func apply(_ err_ptr: inout Error, _ message: String, _ file: String = #file, _ line: UInt = #line, _ function: String = #function) -> ErrInfo {
		return ErrInfo(&err_ptr, message, file, line, function)
	}
}

@inline(__always)
func !> <T>(value: @autoclosure @escaping () throws -> T, _ err: ErrInfo) -> T? {
	do {
		return try value()
	} catch let errd {
		err.err_ptr.pointee = MError(err.message, root: errd, __file: err.file, __function: err.function, __line: err.line)
		return nil
	}
}

@inline(__always)
func !>> <T>(value: @Sendable @autoclosure @escaping () async throws -> T, _ err: ErrInfo) async -> T? {
    do {
        return try await value()
    } catch let errd {
        err.err_ptr.pointee = MError(err.message, root: errd, __file: err.file, __function: err.function, __line: err.line)
        return nil
    }
}

extension Result {
	@inline(__always)
	static func !> (result: Result, err: inout Error) -> Success? {
		return try result.get() !> err
	}

	@inline(__always)
	static func !> (result: Result, err: ErrInfo) -> Success? {
		return try result.get() !> err
	}
}

public extension Result where Failure == Error, Success: ~Copyable {
	init(
		catching body: () throws -> Success
	) {
		do {
			let result = try body()
			self = .success(result)
		} catch {
			self = .failure(error)
		}
	}

	init(
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

