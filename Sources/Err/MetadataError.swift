import Logging

extension Error {
	public typealias WithMessage = ErrorWithMessage
	public typealias WithLoggerMetadata = ErrorWithLoggerMetadata
}

public protocol ErrorWithMessage {
	var message: String { get }
}

public protocol ErrorWithLoggerMetadata {
	var metadata: Logger.Metadata { get }
}
