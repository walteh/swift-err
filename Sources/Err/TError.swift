import Logging

struct BaseError: Error {}

public struct TError: Swift.Error {
	public let message: String
	public let root: Error
	public var metadata: Logger.Metadata
	public let caller: Caller

	public static let base: Error = BaseError()

	public init(
		_ message: String,
		__file: String = #fileID,
		__function: String = #function,
		__line: UInt = #line
	) {
		self.init(
			message,
			root: TError.base,
			__file: __file,
			__function: __function,
			__line: __line
		)
	}

	public init(
		_ message: String,
		root: Error,
		__file: String = #fileID,
		__function: String = #function,
		__line: UInt = #line
	) {
		self.message = message
		self.root = root
		self.caller = Caller(file: __file, function: __function, line: __line)
		self.metadata = [:]
		self.metadata["function"] = .string(__function)
	}

	public func info(_ key: String, _ value: Any) -> Self {
		var copy = self
		copy.metadata[key] = .stringConvertible(String(describing: value))
		return copy
	}

	public func info(_ data: [String: Any]) -> Self {
		var copy = self
		for (key, value) in data {
			copy.metadata[key] = .stringConvertible(String(describing: value))
		}
		return copy
	}

	public func event(_ manip: (LogEvent) -> LogEvent) -> Self {
		var event = LogEvent(.error)
		event = manip(event)
		return self.info(event.metadata)
	}
}

public protocol RootListableError: Error {
	var root: Error { get }
}

extension TError: RootListableError {}

public extension Error {
	func contains(_ error: Error) -> Bool {
		guard let rootable = self as? RootListableError else { return false }
		return rootable.deepest(matching: error) != nil
	}

	func contains<T: Error>(_ type: T.Type) -> Bool {
		guard let rootable = self as? RootListableError else { return false }
		return rootable.deepest(ofType: T.self) != nil
	}
}

public extension RootListableError {
	func rootErrorList() -> [Error] {
		var errors = [Error]()
		errors.append(self)

		var current: Error? = self.root
		while let error = current {
			errors.append(error)
			current = (error as? RootListableError)?.root
		}

		return errors.reversed()
	}

	func deepest<T: Error>(ofType: T.Type) -> Error? {
		return rootErrorList().first { $0 is T }
	}

	func deepest(matching error: Error) -> Error? {
		return rootErrorList().first { "\($0)" == "\(error)" }
	}
}

extension TError: CustomStringConvertible, CustomDebugStringConvertible {
	public var description: String {
		return "TError[ message=\"\(message)\" caller=\"\(caller.format())\" ]"
	}

	public var debugDescription: String {
		let descriptions = rootErrorList().map { "\($0)" }
		return descriptions.joined(separator: " 👉 ")
	}
}
