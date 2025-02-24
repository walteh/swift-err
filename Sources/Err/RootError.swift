public protocol RootError: Error, CustomStringConvertible {
	var root: Error { get }
}

public struct BaseRootError: RootError {
	public let root: any Error

	public init(root: any Error) {
		self.root = root
	}
}

extension RootError {
	public var description: String {
		"\(root)"
	}

	public func rootErrorList() -> [Error] {
		var errors = [Error]()
		errors.append(self)

		// we may want to remove wrapped

		var current: Error? = root
		while let error = current {
			errors.append(error)
			current = (error as? RootError)?.root
		}

		return errors.reversed()
	}

	public func deepest<T: Error>(ofType _: T.Type) -> Error? {
		rootErrorList().first { $0 is T }
	}

	public func deepest(matching error: Error) -> Error? {
		rootErrorList().first { "\($0)" == "\(error)" }
	}
}

extension Error {
	public func contains(_ error: Error) -> Bool {
		guard let rootable = self as? RootError else { return false }
		return rootable.deepest(matching: error) != nil
	}

	public func contains<T: Error>(_: T.Type) -> Bool {
		guard let rootable = self as? RootError else { return false }
		return rootable.deepest(ofType: T.self) != nil
	}
}
