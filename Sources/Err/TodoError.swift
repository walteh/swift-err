public struct TODOError: Error {
	var description: String {
		"TODO: consider defining an explicit cause for this error"
	}
}

extension Error {
	public typealias TODO = TODOError
}
