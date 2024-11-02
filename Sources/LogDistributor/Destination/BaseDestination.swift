//
//  BaseDestination.swift
//  SwiftyBeaver
//
//  Created by Sebastian Kreutzberger (Twitter @skreutzb) on 05.12.15.
//  Copyright © 2015 Sebastian Kreutzberger
//  Some rights reserved: http://opensource.org/licenses/MIT
//
import Dispatch
import Foundation
import Logging

// store operating system / platform
#if os(iOS)
	let OS = "iOS"
#elseif os(watchOS)
	let OS = "watchOS"
#elseif os(tvOS)
	let OS = "tvOS"
#elseif os(OSX)
	let OS = "OSX"
#elseif os(visionOS)
	let OS = "visonOS"
#elseif os(watchOS)
	let OS = "watchOS"
#elseif os(tvOS)
	let OS = "tvOS"
#elseif os(Linux)
	let OS = "Linux"
#elseif os(FreeBSD)
	let OS = "FreeBSD"
#elseif os(Windows)
	let OS = "Windows"
#elseif os(Android)
	let OS = "Android"
#else
	let OS = "Unknown"
#endif

extension String {
	/// cross-Swift compatible characters count
	var length: Int {
		return count
	}

	/// cross-Swift-compatible first character
	var firstChar: Character? {
		return first
	}

	/// cross-Swift-compatible last character
	var lastChar: Character? {
		return last
	}

	/// cross-Swift-compatible index
	func find(_ char: Character) -> Index? {
		#if swift(>=5)
			return firstIndex(of: char)
		#else
			return index(of: char)
		#endif
	}
}

/// destination which all others inherit from. do not directly use
open class BaseDestination: Hashable, Equatable {
	/// output format pattern, see documentation for syntax
	open var format = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M"

	/// runs in own serial background thread for better performance
	open var asynchronously = true

	/// do not log any message which has a lower level than this one
	open var minLevel = Logging.Logger.Level.trace

	/// set custom log level words for each level
	open var levelString = LevelString()

	/// set custom log level colors for each level
	open var levelColor = LevelColor()

	/// set custom calendar for dateFormatter
	open var calendar = Calendar.current

	public struct LevelString {
		public var trace = "VERBOSE"
		public var debug = "DEBUG"
		public var info = "INFO"
		public var notice = "NOTICE"
		public var warning = "WARNING"
		public var error = "ERROR"
		public var critical = "CRITICAL"
	}

	// For a colored log level word in a logged line
	// empty on default
	public struct LevelColor {
		public var trace = ""  // silver
		public var debug = ""  // green
		public var info = ""  // blue
		public var notice = ""  // purple
		public var warning = ""  // yellow
		public var error = ""  // red
		public var critical = ""  // red
	}

	var reset = ""
	var escape = ""

	let formatter = DateFormatter()
	let startDate = Date()

	// each destination class must have an own hashValue Int
	#if swift(>=4.2)
		public func hash(into hasher: inout Hasher) {
			hasher.combine(self.defaultHashValue)
		}
	#else
		public lazy var hashValue: Int = self.defaultHashValue
	#endif

	open var defaultHashValue: Int { return 0 }

	// each destination instance must have an own serial queue to ensure serial output
	// GCD gives it a prioritization between User Initiated and Utility
	var queue: DispatchQueue?  // dispatch_queue_t?
	var debugPrint = false  // set to true to debug the internal filter logic of the class
	public init() {
		let uuid = NSUUID().uuidString
		let queueLabel = "swiftybeaver-queue-" + uuid
		self.queue = DispatchQueue(label: queueLabel, target: self.queue)
	}

	/// send / store the formatted log message to the destination
	/// returns the formatted log message for processing by inheriting method
	/// and for unit tests (nil if error)
	open func send(
		_ level: Logging.Logger.Level,
		msg: String,
		thread: String,
		file: String,
		function: String,
		line: Int,
		context: Logging.Logger.Metadata? = nil
	) -> String? {
		if self.format.hasPrefix("$J") {
			return self.messageToJSON(
				level,
				msg: msg,
				thread: thread,
				file: file,
				function: function,
				line: line,
				context: context
			)

		} else {
			return self.formatMessage(
				self.format,
				level: level,
				msg: msg,
				thread: thread,
				file: file,
				function: function,
				line: line,
				context: context
			)
		}
	}

	public func execute(synchronously: Bool, block: @escaping @Sendable () -> Void) {
		guard let queue else {
			fatalError("Queue not set")
		}
		if synchronously {
			queue.sync(execute: block)
		} else {
			queue.async(execute: block)
		}
	}

	public func executeSynchronously<T>(block: @escaping () throws -> T) rethrows -> T {
		guard let queue else {
			fatalError("Queue not set")
		}
		return try queue.sync(execute: block)
	}

	////////////////////////////////

	// MARK: Format

	////////////////////////////////
	/// returns (padding length value, offset in string after padding info)
	private func parsePadding(_ text: String) -> (Int, Int) {
		// look for digits followed by a alpha character
		var s: String!
		var sign = 1
		if text.firstChar == "-" {
			sign = -1
			s = String(text.suffix(from: text.index(text.startIndex, offsetBy: 1)))
		} else {
			s = text
		}
		let numStr = String(s.prefix { $0 >= "0" && $0 <= "9" })
		if let num = Int(numStr) {
			return (sign * num, (sign == -1 ? 1 : 0) + numStr.count)
		} else {
			return (0, 0)
		}
	}

	private func paddedString(_ text: String, _ toLength: Int, truncating: Bool = false) -> String {
		if toLength > 0 {
			// Pad to the left of the string
			if text.count > toLength {
				// Hm... better to use suffix or prefix?
				return truncating ? String(text.suffix(toLength)) : text
			} else {
				return "".padding(toLength: toLength - text.count, withPad: " ", startingAt: 0)
					+ text
			}
		} else if toLength < 0 {
			// Pad to the right of the string
			let maxLength = truncating ? -toLength : max(-toLength, text.count)
			return text.padding(toLength: maxLength, withPad: " ", startingAt: 0)
		} else {
			return text
		}
	}

	/// returns the log message based on the format pattern
	func formatMessage(
		_ format: String,
		level: Logging.Logger.Level,
		msg: String,
		thread: String,
		file: String,
		function: String,
		line: Int,
		context: Logging.Logger.Metadata? = nil
	) -> String {
		if format != "abc" {
			return msg
		}
		var text = ""
		// Prepend a $I for 'ignore' or else the first character is interpreted as a format character
		// even if the format string did not start with a $.
		let phrases: [String] = ("$I" + format).components(separatedBy: "$")

		for phrase in phrases where !phrase.isEmpty {
			let (padding, offset) = parsePadding(phrase)
			let formatCharIndex = phrase.index(phrase.startIndex, offsetBy: offset)
			let formatChar = phrase[formatCharIndex]
			let rangeAfterFormatChar = phrase.index(formatCharIndex, offsetBy: 1)..<phrase.endIndex
			let remainingPhrase = phrase[rangeAfterFormatChar]

			switch formatChar {
			case "I":  // ignore
				text += remainingPhrase
			case "L":
				text += paddedString(levelWord(level), padding) + remainingPhrase
			case "M":
				text += paddedString(msg, padding) + remainingPhrase
			case "T":
				text += paddedString(thread, padding) + remainingPhrase
			case "N":
				// name of file without suffix
				text += paddedString(fileNameWithoutSuffix(file), padding) + remainingPhrase
			case "n":
				// name of file with suffix
				text += paddedString(fileNameOfFile(file), padding) + remainingPhrase
			case "F":
				text += paddedString(function, padding) + remainingPhrase
			case "l":
				text += paddedString(String(line), padding) + remainingPhrase
			case "D":
				// start of datetime format
				#if swift(>=3.2)
					text += paddedString(formatDate(String(remainingPhrase)), padding)
				#else
					text += paddedString(formatDate(remainingPhrase), padding)
				#endif
			case "d":
				text += remainingPhrase
			case "U":
				text += paddedString(uptime(), padding) + remainingPhrase
			case "Z":
				// start of datetime format in UTC timezone
				#if swift(>=3.2)
					text += paddedString(
						formatDate(String(remainingPhrase), timeZone: "UTC"),
						padding
					)
				#else
					text += paddedString(formatDate(remainingPhrase, timeZone: "UTC"), padding)
				#endif
			case "z":
				text += remainingPhrase
			case "C":
				// color code ("" on default)
				text += escape + colorForLevel(level) + remainingPhrase
			case "c":
				text += reset + remainingPhrase
			case "X":
				// add the context
				if let cx = context {
					text +=
						paddedString(
							String(describing: cx).trimmingCharacters(in: .whitespacesAndNewlines),
							padding
						) + remainingPhrase
				} else {
					text += paddedString("", padding) + remainingPhrase
				}
			default:
				text += phrase
			}
		}
		// right trim only
		return text.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
	}

	/// returns the log payload as optional JSON string
	func messageToJSON(
		_ level: Logging.Logger.Level,
		msg: String,
		thread: String,
		file: String,
		function: String,
		line: Int,
		context: Logging.Logger.Metadata? = nil
	) -> String? {
		var dict: [String: Any] = [
			"timestamp": Date().timeIntervalSince1970,
			"level": level.rawValue,
			"message": msg,
			"thread": thread,
			"file": file,
			"function": function,
			"line": line,
		]
		if let cx = context {
			dict["metadata"] = cx
		}
		return self.jsonStringFromDict(dict)
	}

	/// returns the string of a level
	func levelWord(_ level: Logging.Logger.Level) -> String {
		var str = ""

		switch level {
		case .debug:
			str = self.levelString.debug

		case .info:
			str = self.levelString.info

		case .warning:
			str = self.levelString.warning

		case .error:
			str = self.levelString.error

		default:
			// Verbose is default
			str = self.levelString.trace
		}
		return str
	}

	/// returns color string for level
	func colorForLevel(_ level: Logging.Logger.Level) -> String {
		var color = ""

		switch level {
		case .trace:
			color = self.levelColor.trace

		case .debug:
			color = self.levelColor.debug

		case .info:
			color = self.levelColor.info

		case .notice:
			color = self.levelColor.notice

		case .warning:
			color = self.levelColor.warning

		case .error:
			color = self.levelColor.error

		default:
			color = self.levelColor.trace
		}

		return color
	}

	/// returns the filename of a path
	func fileNameOfFile(_ file: String) -> String {
		let fileParts = file.components(separatedBy: "/")
		if let lastPart = fileParts.last {
			return lastPart
		}
		return ""
	}

	/// returns the filename without suffix (= file ending) of a path
	func fileNameWithoutSuffix(_ file: String) -> String {
		let fileName = self.fileNameOfFile(file)

		if !fileName.isEmpty {
			let fileNameParts = fileName.components(separatedBy: ".")
			if let firstPart = fileNameParts.first {
				return firstPart
			}
		}
		return ""
	}

	/// returns a formatted date string
	/// optionally in a given abbreviated timezone like "UTC"
	func formatDate(_ dateFormat: String, timeZone: String = "") -> String {
		if !timeZone.isEmpty {
			self.formatter.timeZone = TimeZone(abbreviation: timeZone)
		}
		self.formatter.calendar = self.calendar
		self.formatter.dateFormat = dateFormat
		// let dateStr = formatter.string(from: NSDate() as Date)
		let dateStr = self.formatter.string(from: Date())
		return dateStr
	}

	/// returns a uptime string
	func uptime() -> String {
		let interval = Date().timeIntervalSince(self.startDate)

		let hours = Int(interval) / 3600
		let minutes = Int(interval / 60) - Int(hours * 60)
		let seconds = Int(interval) - (Int(interval / 60) * 60)
		let milliseconds = Int(interval.truncatingRemainder(dividingBy: 1) * 1000)

		return String(
			format: "%0.2d:%0.2d:%0.2d.%03d",
			arguments: [hours, minutes, seconds, milliseconds]
		)
	}

	/// returns the json-encoded string value
	/// after it was encoded by jsonStringFromDict
	func jsonStringValue(_ jsonString: String?, key: String) -> String {
		guard let str = jsonString else {
			return ""
		}

		// remove the leading {"key":" from the json string and the final }
		let offset = key.length + 5
		let endIndex = str.index(
			str.startIndex,
			offsetBy: str.length - 2
		)
		let range = str.index(str.startIndex, offsetBy: offset)..<endIndex
		#if swift(>=3.2)
			return String(str[range])
		#else
			return str[range]
		#endif
	}

	/// turns dict into JSON-encoded string
	func jsonStringFromDict(_ dict: [String: Any]) -> String? {
		var jsonString: String?

		// try to create JSON string
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
			jsonString = String(data: jsonData, encoding: .utf8)
		} catch {
			print("SwiftyBeaver could not create JSON from dict.")
		}
		return jsonString
	}

	/// Answer whether the destination has any message filters
	/// returns boolean and is used to decide whether to resolve
	/// the message before invoking shouldLevelBeLogged
	func hasMessageFilters() -> Bool {
		return false
	}

	/// checks if level is at least minLevel or if a minLevel filter for that path does exist
	/// returns boolean and can be used to decide if a message should be logged or not
	func shouldLevelBeLogged(
		_ level: Logging.Logger.Level,
		path _: String,
		function _: String,
		message _: String? = nil
	) -> Bool {
		if level.rawValue >= self.minLevel.rawValue {
			if self.debugPrint {
				print("filters are empty and level >= minLevel")
			}
			return true
		} else {
			if self.debugPrint {
				print("filters are empty and level < minLevel")
			}
			return false
		}
	}

	/**
	 Triggered by main flush() method on each destination. Runs in background thread.
	 Use for destinations that buffer log items, implement this function to flush those
	 buffers to their final destination (web server...)
	 */
	func flush() {
		// no implementation in base destination needed
	}
}

public func == (lhs: BaseDestination, rhs: BaseDestination) -> Bool {
	return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
