public struct NilError: Error {
	static let `nil` = NilError()
	private init() {}
}

extension Error where Self == Error {
	public typealias Nil = NilError

	public static var `nil`: Error {
		NilError.nil
	}

	public var isNil: Bool {
		self is Error.Nil
	}

	public var isNotNil: Bool {
		!(self is Error.Nil)
	}
}
