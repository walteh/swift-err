import Err

public actor ErrorBroadcaster {
	public typealias HandlerFunc = @Sendable (any Error) -> Void

	private static var handlers: [HandlerFunc] = []

	public static func addHandler(_ handler: @escaping HandlerFunc) {
		handlers.append(handler)
	}

	public static func broadcast(_ error: any Error) {
		for handler in handlers {
			Task {
				handler(error)
			}
		}
	}
}

public extension MError {
	func notify() -> Self {
		ErrorBroadcaster.broadcast(self)
		return self
	}
}
