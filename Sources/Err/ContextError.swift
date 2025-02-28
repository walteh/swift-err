import Logging

public struct ContextError: Error.WithCause, Error.WithCaller, Error.WithMessage, Error.WithLoggerMetadata {
	public let message: String
	public var metadata: Logger.Metadata
	public let caller: Caller
	public let cause: Error

	public init(
		_ message: String,
		cause: Error? = nil,
		__file: String = #fileID,
		__function: String = #function,
		__line: UInt = #line
	) {
		self.message = message
		self.cause = cause ?? TODOError()
		self.caller = Caller(
			file: __file,
			function: __function,
			line: __line
		)
		metadata = [:]
		metadata["function"] = .string(__function)
	}
}

extension ContextError {
	public func info(_ key: String, _ value: Any) -> Self {
		var copy = self
		copy.metadata[key] = .stringConvertible(String(describing: value))
		return copy
	}

	public func info(_ data: [String: Any]) -> Self {
		var copy = self
		for (key, value) in data {
			copy.metadata[key] = .stringConvertible(String(describing: value))
		}
		return copy
	}
}

extension ContextError: CustomStringConvertible, CustomDebugStringConvertible {
	public var description: String {
		"[ message=\"\(message)\" caller=\"\(caller.format())\" ]"
	}

	public var debugDescription: String {
		let descriptions = causeErrorList().map { "\($0)" }
		return descriptions.joined(separator: " 👉 ")
	}
}
