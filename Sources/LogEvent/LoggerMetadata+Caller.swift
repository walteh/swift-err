import Err
import Logging

public extension Logger.Metadata {
	mutating func setCaller(_ caller: Caller) {
		self["file"] = .string(caller.file)
		self["function"] = .string(caller.function)
		self["line"] = .string(String(caller.line))
	}

	func getCaller() -> Caller {
		return Caller(
			file: self["file"]?.description ?? "",
			function: self["function"]?.description ?? "",
			line: self["line"]?.description ?? ""
		)
	}

	mutating func clearCaller() {
		self.removeValue(forKey: "file")
		self.removeValue(forKey: "line")
		self.removeValue(forKey: "function")
	}
}
