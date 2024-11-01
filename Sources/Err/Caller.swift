//
//  Caller.swift
//
//
//  Created by walter on 1/24/24.
//

import Foundation
import Logging

public struct Caller {
	public let file: String
	public let function: String
	public let line: UInt

	public static func build(file: String, function: String, line: UInt) -> Caller {
		return Caller(file: file, function: function, line: line)
	}

	public func merge(into other: Caller) -> Caller {
		return Caller(
			file: other.file.isEmpty ? self.file : other.file,
			function: other.function.isEmpty ? self.function : other.function,
			line: other.line == 0 ? self.line : other.line
		)
	}

	/// returns the filename of a path
	func fileNameOfFile() -> String {
		let fileParts = self.file.components(separatedBy: "/")
		if let lastPart = fileParts.last {
			return lastPart
		}
		return ""
	}

	func targetOfFile() -> String {
		let fileParts = self.file.components(separatedBy: "/")
		if var firstPart = fileParts.first {
			firstPart = firstPart.replacingOccurrences(of: "", with: "").replacingOccurrences(
				of: "_",
				with: "/"
			)
			return firstPart
		}
		return ""
	}

	/// returns the filename without suffix (= file ending) of a path
	func fileNameWithoutSuffix() -> String {
		let fileName = self.fileNameOfFile()

		if !fileName.isEmpty {
			let fileNameParts = fileName.components(separatedBy: ".")
			if let firstPart = fileNameParts.first {
				return firstPart
			}
		}
		return ""
	}

	public func format<T: PrettyCallerFormatter>(
		with formatter: T = NoopPrettyCallFormatter()
	) -> T.OUTPUT {
		var functionStr = ""
		if self.function.contains("(") {
			let mid = self.function.split(separator: "(")
			functionStr = String(mid.first!) + String(mid[1] == ")" ? "()" : "(...)")
		} else {
			functionStr = self.function
		}

		let dullsep = formatter.format(seperator: ":")
		let spacesep = formatter.format(seperator: " ")

		_ = formatter.format(function: functionStr)  // not in use right now, but maybe later
		let filename = formatter.format(file: self.fileNameOfFile())
		let targetName = formatter.format(target: self.targetOfFile())
		let lineName = formatter.format(line: String(self.line))

		return targetName + spacesep + filename + dullsep + lineName
	}
}

public protocol PrettyCallerFormatter {
	associatedtype OUTPUT: CustomStringConvertible, RangeReplaceableCollection
	func format(function: String) -> OUTPUT
	func format(line: String) -> OUTPUT
	func format(file: String) -> OUTPUT
	func format(target: String) -> OUTPUT
	func format(seperator: String) -> OUTPUT
}

public struct NoopPrettyCallFormatter: PrettyCallerFormatter {
	public init() {}
	public func format(function: String) -> String {
		return function
	}

	public func format(line: String) -> String {
		return line
	}

	public func format(file: String) -> String {
		return file
	}

	public func format(target: String) -> String {
		return target
	}

	public func format(seperator: String) -> String {
		return seperator
	}
}

public extension Logging.Logger.Metadata {
	func getCaller() -> Caller {
		return Caller(
			file: self["file"]?.description ?? "",
			function: self["function"]?.description ?? "",
			line: (try? UInt(self["line"]?.description ?? "", format: .number)) ?? 0
		)
	}

	mutating func clearCaller() {
		self.removeValue(forKey: "file")
		self.removeValue(forKey: "line")
		self.removeValue(forKey: "function")
	}
}
