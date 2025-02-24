import Logging

public protocol MessageError {
	var message: String { get }
}

public protocol MetadataError {
	var metadata: Logger.Metadata { get }
}

public struct MError: RootError, CallError, MessageError, MetadataError {
	public let message: String
	public var metadata: Logger.Metadata
	public let cerror: CError

	public var root: Error {
		cerror.root
	}

	public var caller: Caller {
		cerror.caller
	}

	public init(
		_ message: String,
		root: Error? = nil,
		__file: String = #fileID,
		__function: String = #function,
		__line: UInt = #line
	) {
		self.message = message
		cerror = CError(
			root: root,
			file: __file,
			function: __function,
			line: __line
		)
		metadata = [:]
		metadata["function"] = .string(__function)
	}
}

extension MError {
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
}

extension MError: CustomStringConvertible, CustomDebugStringConvertible {
	public var description: String {
		"[ message=\"\(message)\" caller=\"\(cerror.caller.format())\" ]"
	}

	public var debugDescription: String {
		let descriptions = rootErrorList().map { "\($0)" }
		return descriptions.joined(separator: " 👉 ")
	}
}
