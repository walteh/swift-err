public protocol RootError: Error, CustomStringConvertible {
	var root: Error { get }
}

public struct BaseRootError: RootError {
	public let root: any Error

	public init(root: any Error) {
		self.root = root
	}
}

public extension RootError {

	var description: String {
		return "\(root)"
	}

	func rootErrorList() -> [Error] {
		var errors = [Error]()
		errors.append(self)

		// we may want to remove wrapped

		var current: Error? = self.root
		while let error = current {
			errors.append(error)
			current = (error as? RootError)?.root
		}

		return errors.reversed()
	}

	func deepest<T: Error>(ofType: T.Type) -> Error? {
		return rootErrorList().first { $0 is T }
	}

	func deepest(matching error: Error) -> Error? {
		return rootErrorList().first { "\($0)" == "\(error)" }
	}

}

public extension Error {
	func contains(_ error: Error) -> Bool {
		guard let rootable = self as? RootError else { return false }
		return rootable.deepest(matching: error) != nil
	}

	func contains<T: Error>(_ type: T.Type) -> Bool {
		guard let rootable = self as? RootError else { return false }
		return rootable.deepest(ofType: T.self) != nil
	}
}
