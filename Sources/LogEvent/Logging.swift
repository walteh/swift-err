import Err
import Logging
import ServiceContextModule

@inline(__always) public func GetContext() -> ServiceContext {
	ServiceContext.current ?? ServiceContext.TODO("you should set a context")
}

public func log(
	_ level: Logging.Logger.Level = .info,
	__file: String = #fileID,
	__function: String = #function,
	__line: UInt = #line
) -> LogEvent {
	LogEvent(level, __file: __file, __function: __function, __line: __line)
}

public final class LogEvent {
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
			skip = true
			self.level = .trace
			self.__file = __file
			self.__line = __line
			self.__function = __function
			error = nil
			return
		}
		skip = false
		self.level = level
		metadata.setCaller(Caller(file: __file, function: __function, line: __line))
		self.__file = __file
		self.__line = UInt(__line)
		self.__function = __function

		for (k, v) in GetContext()[LoggerMetadataContextKey.self] ?? [:] {
			metadata[k] = v
		}
	}

	public subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
		get {
			metadata[key]
		}
		set(newValue) {
			metadata[key] = newValue
		}
	}

	public var metadata: Logging.Logger.Metadata = [:]

	public func err(_ err: Swift.Error?) -> Self {
		if skip { return self }
		error = err
		if let err {
			metadata.setDumpedError(err)
		}
		return self
	}

	@inlinable
	public func send(_ message: @autoclosure () -> Logger.Message) {
		if skip { return }

		GetContext().logger.log(
			level: level,
			message(),
			metadata: metadata,
			source: nil,
			file: __file,
			function: __function,
			line: __line
		)
	}
}

let dumpedErrorKey = "dumped_error"

extension Logger.Metadata {
	@usableFromInline internal mutating func setDumpedError(_ input: Error) {
		if let err = input as? ErrorWithCause {
			self[dumpedErrorKey] = .stringConvertible(err)
		} else {
			self[dumpedErrorKey] = .stringConvertible(CauseError(cause: input))
		}
	}

	public mutating func getAndClearDumpedError() -> ErrorWithCause? {
		if let val = self[dumpedErrorKey] {
			self[dumpedErrorKey] = nil
			if case let .stringConvertible(str) = val {
				if let err = str as? ErrorWithCause {
					return err
				}
			}
		}
		return nil
	}
}

extension LogEvent {
	@inline(__always)
	public func info(_ key: String, string: String) -> Self {
		if skip { return self }
		self[metadataKey: key] = .string(string)
		return self
	}

	@inline(__always)
	public func info(_ key: String, any: CustomStringConvertible & Sendable) -> Self {
		if skip { return self }
		self[metadataKey: key] = .stringConvertible(any)
		return self
	}

	@inline(__always)
	public func info(_ key: String, _ s: some CustomDebugStringConvertible) -> Self {
		if skip { return self }
		self[metadataKey: key] = .string(s.debugDescription)
		return self
	}

	@inline(__always)
	public func meta(_ data: Logging.Logger.Metadata) -> Self {
		if skip { return self }
		for (k, v) in data {
			metadata[k] = v
		}
		return self
	}
}
