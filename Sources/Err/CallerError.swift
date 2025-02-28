public protocol ErrorWithCaller: Error {
	var caller: Caller { get }
}

extension Error {
	public typealias WithCaller = ErrorWithCaller
}

public struct CallerError: Error.WithCause, Error.WithCaller {
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
