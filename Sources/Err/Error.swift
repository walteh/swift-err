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
}
