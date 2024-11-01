//
//  Logging.swift
//  app
//
//  Created by walter on 9/29/22.
//

import Foundation
import Logging
import ServiceContextModule

@inlinable public func GetContext() -> ServiceContext {
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

// public extension x {
// 	static func log(
// 		_ level: Logging.Logger.Level = .info,
// 		__file: String = #fileID,
// 		__function: String = #function,
// 		__line: UInt = #line
// 	) -> LogEvent {
// 		return Log(level, __file: __file, __function: __function, __line: __line)
// 	}
// }

public extension ServiceContext {
	var logger: Logging.Logger {
		return self[LoggerContextKey.self] ?? xlogger
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

let xlogger = Logger(label: Bundle.main.bundleIdentifier ?? "unknown")

public class LogEvent {
	public let level: Logging.Logger.Level
	public let caller: String
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
		self.level = level
		self.metadata["function"] = .string(__function)
		self.caller = "\(__file.split(separator: "/").last!):\(__line)"
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

	public func err(_ err: Swift.Error?) -> Self {
		self.error = err
		return self
	}

	public func add(_ key: String, string: String) -> Self {
		return self.info(key, string)
	}

	public func add(_ key: String, any: CustomStringConvertible & Sendable) -> Self {
		return self.info(key, any: any)
	}

	public func add(_ key: String, _ s: some CustomDebugStringConvertible) -> Self {
		return self.info(key, s)
	}

	public func info(_ key: String, string: String) -> Self {
		self[metadataKey: key] = .string(string)
		return self
	}

	public func info(_ key: String, any: CustomStringConvertible & Sendable) -> Self {
		self[metadataKey: key] = .stringConvertible(any)
		return self
	}

	@inlinable
	public func info(_ key: String, _ s: some CustomDebugStringConvertible) -> Self {
		self[metadataKey: key] = .string(s.debugDescription)
		return self
	}

	public func meta(_ data: Logging.Logger.Metadata) -> Self {
		for (k, v) in data {
			self.metadata[k] = v
		}
		return self
	}

	@inlinable
	public func send(_ str: some CustomDebugStringConvertible) {
		if let err = self.error {
			self.metadata.setDumpedError(err)
		}
		GetContext().logger.log(
			level: self.level,
			.init(stringLiteral: str.debugDescription),
			metadata: self.metadata,
			source: self.caller,
			file: self.__file,
			function: self.__function,
			line: self.__line
		)
	}
}

let dumpedErrorKey = "dumped_error"

public extension Logger.Metadata {
	@usableFromInline internal mutating func setDumpedError(_ input: Error) {
		self[dumpedErrorKey] = .stringConvertible(input as NSError)
		return
	}

	mutating func getAndClearDumpedError() -> NSError? {
		if let val = self[dumpedErrorKey] {
			self[dumpedErrorKey] = nil
			if case let .stringConvertible(str) = val {
				if let err = str as? NSError {
					return err
				}
			}
		}
		return nil
	}
}
