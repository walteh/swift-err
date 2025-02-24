public struct EmptyError: Error {
	fileprivate static let constant = EmptyError()
	fileprivate init() {}
}

extension Error {
	public static var empty: Error {
		EmptyError.constant
	}
}
