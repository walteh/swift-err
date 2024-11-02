//
//  ConsoleHandler.swift
//
//
//  Created by walter on 3/7/23.
//

import Err
import Foundation
import LogEvent
import Logging

/// Outputs logs to a `Console`.
public struct ConsoleLogger: Logging.LogHandler, Sendable {
	public let label: String

	/// See `LogHandler.metadata`.
	public var metadata: Logger.Metadata

	/// See `LogHandler.metadataProvider`.
	public var metadataProvider: Logger.MetadataProvider?

	/// See `LogHandler.logLevel`.
	public var logLevel: Logger.Level

	struct OutputFile {
		let url: URL
		public let fileLogger: FileDestination

		init() {
			let url: URL = .cachesDirectory.appending(
				component: "\(Bundle.main.bundleIdentifier ?? "unknown").logs.log"
			)
			self.url = url
			self.fileLogger = FileDestination(logFileURL: url)

			print(
				"\n================ to view logs =================\n"
					+ "tail -f -n100 \(self.url.relativeString.replacingOccurrences(of: "file://", with: ""))\n"
					+ "==================================================="
			)
		}
	}

	@MainActor static let outputFile = OutputFile()

	/// The conosle that the messages will get logged to.
	/// Creates a new `ConsoleLogger` instance.
	///
	/// - Parameters:
	///   - label: Unique identifier for this logger.
	///   - console: The console to log the messages to.
	///   - level: The minimum level of message that the logger will output. This defaults to `.debug`, the lowest level.
	///   - metadata: Extra metadata to log with the message. This defaults to an empty dictionary.

	public init(
		label: String,
		level: Logger.Level = .debug,
		metadata: Logger.Metadata = [:],
		metadataProvider: Logger.MetadataProvider? = nil
	) {
		self.label = label
		self.metadata = metadata
		self.logLevel = level
		self.metadataProvider = metadataProvider
	}

	/// See `LogHandler[metadataKey:]`.
	///
	/// This just acts as a getter/setter for the `.metadata` property.
	public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
		get { return self.metadata[key] }
		set { self.metadata[key] = newValue }
	}

	public func log(
		level: Logger.Level,
		message: Logger.Message,
		metadata: Logger.Metadata?,
		source: String,
		file: String,
		function: String,
		line: UInt
	) {
		var metadata = metadata

		let mainCaller = Caller(file: file, function: function, line: line)

		var text: ConsoleText = "[\(label)] "

		text += "\(level.name)".consoleText(level.style) + " "

		text += formatDate("HH:mm:ss.SSS").consoleText(color: .palette(242)) + " "

		text += "[ ".consoleText(color: .palette(245))
		text += String(Thread.current.queueName).padding(toLength: 15, withPad: ".", startingAt: 0)
			.consoleText(color: .palette(253))
		text += " ]".consoleText(color: .palette(245)) + " "

		if metadata != nil {
			let caller = metadata!.getCaller()
			metadata!.clearCaller()
			let updatedCaller = caller.merge(into: mainCaller)
			text += updatedCaller.format(with: ConsoleTextPrettyCallFormatter()) + " "
		}

		text += " " + message.description.consoleText()

		let allMetadata = (metadata ?? [:])
			.merging(self.metadata, uniquingKeysWith: { a, _ in a })
			.merging(self.metadataProvider?.get() ?? [:], uniquingKeysWith: { a, _ in a })

		if !allMetadata.isEmpty {
			// only log metadata if not empty
			text += " " + allMetadata.sortedDescriptionWithoutQuotes
		}

		if let err = metadata?.getAndClearDumpedError() {
			text += "\n" + err.dump() + "\n"
		}

		let strtxt = text.terminalStylize()
		// run this in main actor
		DispatchQueue.main.async {
			_ = ConsoleLogger.outputFile.fileLogger.preformattedSend(
				msg: "\(strtxt)"
			)
		}
	}
}

public extension Logger.Level {
	/// Converts log level to console style
	var style: ConsoleStyle {
		switch self {
		case .trace, .debug: return .init(color: .perrywinkle)
		case .info, .notice: return .init(color: .palette(33))
		case .warning: return .warning
		case .error: return .error
		case .critical: return ConsoleStyle(color: .brightRed)
		}
	}

	var name: String {
		switch self {
		case .trace: return "TRC"
		case .debug: return "DBG"
		case .info: return "INF"
		case .notice: return "NTC"
		case .warning: return "WRN"
		case .error: return "ERR"
		case .critical: return "CRT"
		}
	}
}

struct ConsoleTextPrettyCallFormatter: Caller.Formatter {
	func format(function: String) -> ConsoleText {
		return function.consoleText(color: .lightBlue)
	}

	func format(line: String) -> ConsoleText {
		return line.consoleText(color: .brightRed, isBold: true)
	}

	func format(file: String) -> ConsoleText {
		return file.consoleText(color: .lightPurple)
	}

	func format(target: String) -> ConsoleText {
		return target.consoleText(color: .orange)
	}

	func format(seperator: String) -> ConsoleText {
		return seperator.consoleText(color: .palette(242))
	}
}

let formatter = DateFormatter()
let startDate = Date()
let calendar = Calendar.current

private extension Logger.Metadata {
	var sortedDescriptionWithoutQuotes: ConsoleText {
		let contents = Array(self).sorted(by: { $0.0 < $1.0 })
		var text = "".consoleText()
		for (key, value) in contents {
			text += formatKeyValue(key: key, value: value)
			text += " "
		}
		return text
	}
}

func formatKeyValue(key: String, value: CustomStringConvertible) -> ConsoleText {
	var value = "\(value)".trimmingPrefix("\"")
	// check the last character of the value,
	if value.last == "\"" {
		// if it's a quote, remove it
		value = value.dropLast()
	}

	let quote = "\"".consoleText(color: .palette(240), isBold: true)

	return formatKeyEqual(key) + quote + "\(value)".consoleText(color: .palette(196)) + quote
}

func formatKeyEqual(_ key: String) -> ConsoleText {
	return key.description.consoleText(color: .palette(243)) + "=".consoleText(color: .palette(240))
}

extension RootError {
	func dump() -> ConsoleText {
		var stream = "".consoleText()

		var list = self.rootErrorList()

		list.reverse()

		stream += "\n"

		// Start with the initial log message
		// stream += "\n\n=============== 🔻 ERROR 🔻 ===============\n\n"

		for i in 0..<list.count {
			if i == list.count - 1 {
				stream += "❌ "
			} else {
				stream += "👇 "
			}

			let quote = "\"".consoleText(color: .palette(240), isBold: true)

			var wrk = "".consoleText()

			if let r = list[i] as? MessageError {
				let mess = r.message.consoleText(color: .brightRed, isBold: true)
				wrk += " " + formatKeyEqual("message") + quote + mess + quote + " "
			}

			if let r = list[i] as? CallError {
				wrk += formatKeyEqual("caller") + quote
				wrk += r.caller.format(with: ConsoleTextPrettyCallFormatter()) + quote + " "
			}

			if let r = list[i] as? NSError {
				let d = r.domain.consoleText(color: .brightCyan, isBold: true)
				let code = "\(r.code)".consoleText(color: .brightRed, isBold: true)
				wrk += " " + formatKeyEqual("domain") + quote + d + quote + " "
				wrk += formatKeyEqual("code") + quote + code + quote + " "
			}

			stream +=
				"[ ".consoleText(color: .palette(245)) + wrk
				+ " ]".consoleText(color: .palette(245))

			stream += "\n"
			if let r = list[i] as? MetadataError {
				for (key, value) in r.metadata {
					stream += "\t" + formatKeyValue(key: key, value: value) + "\n"
				}
			} else {
				let r = list[i] as NSError
				for (key, value) in r.userInfo {
					if let value = value as? CustomStringConvertible {
						stream += "\t" + formatKeyValue(key: key, value: value) + "\n"
					} else {
						stream += "\t" + formatKeyValue(key: key, value: "\(value)") + "\n"
					}
				}
			}

			stream += "\n"
		}

		// show the debug desc for the final one
		if let r = list.last as? CustomDebugStringConvertible {
			stream += "\n"
			stream += "🔍 \n"
			stream += r.debugDescription.consoleText(color: .brightRed, isBold: true)
			stream += "\n"
		}

		// Finish with the closing log message
		// stream += "===========================================\n\n"

		// Print the entire accumulated log
		return stream
	}
}

/// returns a formatted date string
/// optionally in a given abbreviated timezone like "UTC"
func formatDate(_ dateFormat: String, timeZone: String = "") -> String {
	if !timeZone.isEmpty {
		formatter.timeZone = TimeZone(abbreviation: timeZone)
	}
	formatter.calendar = calendar
	formatter.dateFormat = dateFormat
	// let dateStr = formatter.string(from: NSDate() as Date)
	let dateStr = formatter.string(from: Date())
	return dateStr
}

/// returns a uptime string
func uptime() -> String {
	let interval = Date().timeIntervalSince(startDate)

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

func messageToJSON(
	_ level: Logging.Logger.Level,
	msg: String,
	thread: String,
	file: String,
	function: String,
	line: Int,
	metadata: Logging.Logger.Metadata
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

	dict["metadata"] = metadata

	return jsonStringFromDict(dict)
}
