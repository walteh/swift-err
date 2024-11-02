import Err

public extension MError {
	public func event(_ manip: (LogEvent) -> LogEvent) -> Self {
		var event = LogEvent(.error)
		event = manip(event)
		return self.info(event.metadata)
	}
}
