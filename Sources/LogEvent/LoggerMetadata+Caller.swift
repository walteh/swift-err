import Err
import Logging

extension Logger.Metadata {
	public mutating func setCaller(_ caller: Caller) {
		self["file"] = .string(caller.file)
		self["function"] = .string(caller.function)
		self["line"] = .string(String(caller.line))
	}

	public func getCaller() -> Caller {
		Caller(
			file: self["file"]?.description ?? "",
			function: self["function"]?.description ?? "",
			line: self["line"]?.description ?? ""
		)
	}

	public mutating func clearCaller() {
		removeValue(forKey: "file")
		removeValue(forKey: "line")
		removeValue(forKey: "function")
	}
}
