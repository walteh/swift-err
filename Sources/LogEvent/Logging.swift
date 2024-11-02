import Err
import Logging
import ServiceContextModule

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
		if let err = input as? RootError {
			self[dumpedErrorKey] = .stringConvertible(err)
		} else {
			self[dumpedErrorKey] = .stringConvertible(BaseRootError(root: input))
		}

		return
	}

	mutating func getAndClearDumpedError() -> RootError? {
		if let val = self[dumpedErrorKey] {
			self[dumpedErrorKey] = nil
			if case let .stringConvertible(str) = val {
				if let err = str as? RootError {
					return err
				}
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
