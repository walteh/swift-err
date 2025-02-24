import Err

extension MError {
	public func event(_ manip: (LogEvent) -> LogEvent) -> Self {
		var event = LogEvent(.error)
		event = manip(event)
		return info(event.metadata)
	}
}
