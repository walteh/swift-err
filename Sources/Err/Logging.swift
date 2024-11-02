//
//  Logging.swift
//  app
//
//  Created by walter on 9/29/22.
//

import Logging
import ServiceContextModule

// actor Logger {
// 	private var logger: Logging.Logger

// 	init(label: String) {
// 		self.logger = Logging.Logger(label: label)
// 	}
// }

// var xlogger: Logger = Logger(label: "default")

// @MainActor public func bootstrapLogging(name: String) {
// 	// xlogger = Logger(label: name)
// 	LoggingSystem.bootstrap { label in
// 		var handler = StreamLogHandler.standardOutput(label: label)
// 		handler.logLevel = .trace
// 		return handler
// 	}
// }

@inline(__always) public func GetContext() -> ServiceContext {
	return ServiceContext.current ?? ServiceContext.TODO("you should set a context")
}

public func log(
	_ level: Logging.Logger.Level = .info,
	__file: String = #fileID,
	__function: String = #function,
	__line: UInt = #line
) -> LogEvent {
	return LogEvent(level, __file: __file, __function: __function, __line: __line)
}

public extension ServiceContext {

	var logger: Logging.Logger {
		return self[LoggerContextKey.self] ?? Logger(label: "default")
	}
}

private struct LoggerContextKey: ServiceContextKey {
	typealias Value = Logger
}

private struct LoggerMetadataContextKey: ServiceContextKey {
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

public struct LogEvent {
	public let skip: Bool
	public let level: Logging.Logger.Level
	public var error: Swift.Error?
	public let __file: String
	public let __function: String
	public let __line: UInt

	public init(
		_ level: Logging.Logger.Level,
		__file: String = #fileID,
		__function: String = #function,
		__line: UInt = #line
	) {
		if GetContext().logger.logLevel > level {
			self.skip = true
			self.level = .trace
			self.__file = __file
			self.__line = __line
			self.__function = __function
			// self.caller = ""
			self.error = nil
			return
		}
		self.skip = false
		self.level = level
		self.metadata.setCaller(Caller(file: __file, function: __function, line: __line))
		self.__file = __file
		self.__line = UInt(__line)
		self.__function = __function

		for (k, v) in GetContext()[LoggerMetadataContextKey.self] ?? [:] {
			self.metadata[k] = v
		}
	}

	public subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
		get {
			return self.metadata[key]
		}
		set(newValue) {
			self.metadata[key] = newValue
		}
	}

	public var metadata: Logging.Logger.Metadata = [:]

	public mutating func err(_ err: Swift.Error?) -> Self {
		if self.skip { return self }
		self.error = err
		if let err = err {
			self.metadata.setDumpedError(err)
		}
		return self
	}

	@inlinable
	public func send(_ message: @autoclosure () -> Logger.Message) {
		if self.skip { return }

		GetContext().logger.log(
			level: self.level,
			message(),
			metadata: self.metadata,
			source: nil,
			file: self.__file,
			function: self.__function,
			line: self.__line
		)

	}
}

let dumpedErrorKey = "dumped_error"

public extension Logger.Metadata {
	@usableFromInline internal mutating func setDumpedError(_ input: Error) {
		// Convert error to string representation
		self[dumpedErrorKey] = .stringConvertible(String(describing: input))
		return
	}

	mutating func getAndClearDumpedError() -> String? {
		if let val = self[dumpedErrorKey] {
			self[dumpedErrorKey] = nil
			if case let .stringConvertible(str) = val {
				return String(describing: str)
			}
		}
		return nil
	}
}

public extension LogEvent {

	@inline(__always)
	mutating func info(_ key: String, string: String) -> Self {
		if self.skip { return self }
		self[metadataKey: key] = .string(string)
		return self
	}

	@inline(__always)
	mutating func info(_ key: String, any: CustomStringConvertible & Sendable) -> Self {
		if self.skip { return self }
		self[metadataKey: key] = .stringConvertible(any)
		return self
	}

	@inline(__always)
	mutating func info(_ key: String, _ s: some CustomDebugStringConvertible) -> Self {
		if self.skip { return self }
		self[metadataKey: key] = .string(s.debugDescription)
		return self
	}

	@inline(__always)
	mutating func meta(_ data: Logging.Logger.Metadata) -> Self {
		if skip { return self }
		for (k, v) in data {
			self.metadata[k] = v
		}
		return self
	}

}
