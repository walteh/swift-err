public protocol ErrorWithCause: Error, CustomStringConvertible {
	var cause: Error { get }
}

extension Error {
	public typealias WithCause = ErrorWithCause
}

public struct CauseError: ErrorWithCause {
	public let cause: any Error

	struct BaseError: Error {}

	public static let base: Error = BaseError()

	public init(cause: any Error) {
		self.cause = cause
	}
}

extension Error.WithCause {
	public var description: String {
		"\(cause)"
	}

	public func causeErrorList() -> [Error] {
		var errors = [Error]()
		errors.append(self)

		// we may want to remove wrapped

		var current: Error? = cause
		while let error = current {
			errors.append(error)
			current = (error as? Error.WithCause)?.cause
		}

		return errors.reversed()
	}

	public func deepest<T: Error>(ofType _: T.Type) -> T? {
		causeErrorList().first { $0 is T } as? T
	}

	public func deepest(matching error: Error) -> Error? {
		causeErrorList().first { "\($0)" == "\(error)" }
	}
}

extension Error {
	public func contains(_ error: Error) -> Bool {
		guard let causeable = self as? Error.WithCause else { return false }
		return causeable.deepest(matching: error) != nil
	}

	public func contains<T: Error>(_: T.Type) -> Bool {
		guard let causeable = self as? Error.WithCause else { return false }
		return causeable.deepest(ofType: T.self) != nil
	}
}
