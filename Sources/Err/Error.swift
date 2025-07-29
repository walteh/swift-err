extension Swift.Error {

	public func `cause`<T: Error>(as type: T.Type) -> T? {
		// deepest error of type T
		guard let err = self as? WithCause else {
			return nil
		}

		return err.deepest(ofType: T.self)
	}

	public func cause() -> Error? {
		guard let err = self as? WithCause else {
			return nil
		}

		return err.deepest(ofType: Error.self)
	}

	public func chain() -> String {
		var result = ""
		var current: Error? = self
		while let err = current {
			if result.isEmpty {
				result += "\(err)"
			} else {
				result += ": \(err)"
			}
			current = err.cause()
		}
		return result
	}

	public func debugDescription() -> String {
		return self.chain()
	}

	public func wrap(
		_ message: String,
		__file: String = #file,
		__function: String = #function,
		__line: UInt = #line
	) -> ContextError {
		ContextError(message, cause: self, __file: __file, __function: __function, __line: __line)
	}

	public var isNotEmtpy: Bool {
		if self is Empty {
			return false
		}
		return true
	}

	public var isEmpty: Bool {
		if self is Empty {
			return true
		}
		return false
	}

}
