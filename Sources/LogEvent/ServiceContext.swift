import Logging
import ServiceContextModule

public extension ServiceContext {

	var logger: Logging.Logger {
		return self[LoggerContextKey.self] ?? Logger(label: "default")
	}
}

private struct LoggerContextKey: ServiceContextKey {
	typealias Value = Logger
}

internal struct LoggerMetadataContextKey: ServiceContextKey {
	typealias Value = Logger.Metadata
}

public func AddLoggerMetadataToContext(_ ok: (LogEvent) -> LogEvent) {
	var ctx = GetContext()
	var metadata = ctx[LoggerMetadataContextKey.self] ?? [:]
	let event = ok(LogEvent(.trace))
	for (k, v) in event.metadata {
		metadata[k] = v
	}
	ctx[LoggerMetadataContextKey.self] = metadata
}

public func AddLoggerToContext(logger: Logger) {
	var ctx = GetContext()
	ctx[LoggerContextKey.self] = logger
}