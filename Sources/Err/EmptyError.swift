public struct ErrorEmpty: Error {
	// fileprivate static let constant = ErrorEmpty()
	init() {}
}

extension Error {
	public typealias Empty = ErrorEmpty
}

// public func empty() -> Error {
// 	ErrorEmpty.constant
// }
