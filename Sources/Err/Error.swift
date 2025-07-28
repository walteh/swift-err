extension Swift.Error {

	public func `cause`<T: Error>(as type: T.Type) -> T? {
		// deepest error of type T
		guard let err = self as? WithCause else {
			return self as? T
		}

		return err.deepest(ofType: T.self)
	}

	public func cause() -> Error? {
		guard let err = self as? WithCause else {
			return self
		}

		return err.deepest(ofType: Error.self)
	}

	public func wrap(
		_ message: String,
		__file: String = #file,
		__function: String = #function,
		__line: UInt = #line
	) -> ContextError {
		ContextError(message, cause: self, __file: __file, __function: __function, __line: __line)
	}
}
