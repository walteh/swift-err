public struct Caller: Sendable {
	public let file: String
	public let function: String
	public let line: String

	public init(file: String, function: String, line: UInt) {
		self.file = file
		self.function = function
		self.line = String(line)
	}

	public init(file: String, function: String, line: String) {
		self.file = file
		self.function = function
		self.line = line
	}

	public func merge(into other: Caller) -> Caller {
		Caller(
			file: other.file.isEmpty ? file : other.file,
			function: other.function.isEmpty ? function : other.function,
			line: other.line.isEmpty || other.line == "0" ? line : other.line
		)
	}

	/// returns the filename of a path
	func fileNameOfFile() -> String {
		let fileParts = file.split(separator: "/")
		if let lastPart = fileParts.last {
			return String(lastPart)
		}
		return ""
	}

	func targetOfFile() -> String {
		let fileParts = file.split(separator: "/")
		if let firstPart = fileParts.first {
			return String(
				firstPart.map {
					$0 == "_" ? "/" : $0
				}
			)
		}
		return ""
	}

	/// returns the filename without suffix (= file ending) of a path
	func fileNameWithoutSuffix() -> String {
		let fileName = fileNameOfFile()

		if !fileName.isEmpty {
			let fileNameParts = fileName.split(separator: ".")
			if let firstPart = fileNameParts.first {
				return String(firstPart)
			}
		}
		return ""
	}

	public func format<T: Formatter>(
		with formatter: T = NoopFormatter()
	) -> T.OUTPUT {
		var functionStr = ""
		if function.contains("(") {
			let mid = function.split(separator: "(")
			functionStr = String(mid.first!) + String(mid[1] == ")" ? "()" : "(...)")
		} else {
			functionStr = function
		}

		let dullsep = formatter.format(seperator: ":")
		let spacesep = formatter.format(seperator: " ")

		_ = formatter.format(function: functionStr)  // not in use right now, but maybe later
		let filename = formatter.format(file: fileNameOfFile())
		let targetName = formatter.format(target: targetOfFile())
		let lineName = formatter.format(line: String(line))

		return targetName + spacesep + filename + dullsep + lineName
	}

	public protocol Formatter {
		associatedtype OUTPUT: CustomStringConvertible, RangeReplaceableCollection
		func format(function: String) -> OUTPUT
		func format(line: String) -> OUTPUT
		func format(file: String) -> OUTPUT
		func format(target: String) -> OUTPUT
		func format(seperator: String) -> OUTPUT
	}

	public struct NoopFormatter: Formatter {
		public init() {}
		public func format(function: String) -> String {
			function
		}

		public func format(line: String) -> String {
			line
		}

		public func format(file: String) -> String {
			file
		}

		public func format(target: String) -> String {
			target
		}

		public func format(seperator: String) -> String {
			seperator
		}
	}
}
