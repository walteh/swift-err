public protocol ErrorWithCaller: Error {
	var file: String { get }
	var function: String { get }
	var line: UInt { get }
}

extension Error {
	public typealias WithCaller = ErrorWithCaller
}

public struct CallerError: Error.WithCause, Error.WithCaller {
	public let message: String
	public let cause: Error
	public let file: String
	public let function: String
	public let line: UInt

	public init(
		message: String,
		cause: Error? = nil,
		__file: String = #file,
		__function: String = #function,
		__line: UInt = #line
	) {
		self.message = message
		self.cause = cause ?? NilError.`nil`
		self.file = __file
		self.function = __function
		self.line = __line
	}

	public init(
		message: String,
		__file: String = #file,
		__function: String = #function,
		__line: UInt = #line
	) {
		self.init(message: message, cause: NilError.`nil`, __file: __file, __function: __function, __line: __line)
	}

	// description
	public var description: String {
		"\(cause) at \(file):\(line) \(function)"
	}
}
