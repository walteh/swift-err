public protocol CallError: Error {
	var caller: Caller { get }
}

public struct CError: RootError, CallError {
	public let root: Error
	public let caller: Caller

	struct BaseError: Error {}

	public static let base: Error = BaseError()

	public init(
		root: Error? = nil,
		file: String,
		function: String,
		line: UInt
	) {
		self.root = root ?? CError.base
		self.caller = Caller(
			file: file,
			function: function,
			line: line
		)
	}

	// description
	public var description: String {
		return "\(root) at \(caller.format()))"
	}
}

public func error(
	_ message: String,
	root: Error? = nil,
	__file: String = #fileID,
	__function: String = #function,
	__line: UInt = #line
) -> MError {
	return MError(
		message,
		root: root,
		__file: __file,
		__function: __function,
		__line: __line
	)
}
