public protocol ErrorWithCaller: Error {
	var caller: Caller { get }
}

public struct CallerError: ErrorWithCause, ErrorWithCaller {
	public let cause: Error
	public let caller: Caller

	struct BaseError: Error {}

	public static let base: Error = BaseError()

	public init(
		cause: Error? = nil,
		file: String,
		function: String,
		line: UInt
	) {
		self.cause = cause ?? BaseError()
		caller = Caller(
			file: file,
			function: function,
			line: line
		)
	}

	// description
	public var description: String {
		"\(cause) at \(caller.format()))"
	}
}

// public func error(
// 	_ message: String,
// 	cause: Error? = nil,
// 	__file: String = #fileID,
// 	__function: String = #function,
// 	__line: UInt = #line
// ) -> ContextError {
// 	ContextError(
// 		message,
// 		cause: cause,
// 		__file: __file,
// 		__function: __function,
// 		__line: __line
// 	)
// }
