//
//  StdOutDestination.swift
//  SwiftyBeaver
//
//  Created by Sebastian Kreutzberger on 05.12.15.
//  Copyright © 2015 Sebastian Kreutzberger
//  Some rights reserved: http://opensource.org/licenses/MIT
//

import Foundation
import Logging

#if canImport(OSLog)
	import OSLog
#endif

open class StdOutDestination: BaseDestination {
	public enum LogPrintWay {
		case logger(subsystem: String, category: String)
		case nslog
		case print
	}

	/// Use this to change the logging method to the console. By default, it is set to .print. You can switch to .logger(subsystem:category:) to utilize the OSLog API.
	public var logPrintWay: LogPrintWay = .print
	/// use NSLog instead of print, default is false
	public var useNSLog = false {
		didSet {
			if useNSLog {
				logPrintWay = .nslog
			}
		}
	}

	/// uses colors compatible to Terminal instead of Xcode, default is false
	public var useTerminalColors: Bool = false {
		didSet {
			if useTerminalColors {
				// bash font color, first value is intensity, second is color
				// see http://bit.ly/1Otu3Zr & for syntax http://bit.ly/1Tp6Fw9
				// uses the 256-color table from http://bit.ly/1W1qJuH
				reset = "\u{001b}[0m"
				escape = "\u{001b}[38;5;"
				levelColor.trace = "251m"  // silver
				levelColor.debug = "35m"  // green
				levelColor.info = "38m"  // blue
				levelColor.notice = "36m"  // cyan
				levelColor.warning = "178m"  // yellow
				levelColor.error = "197m"  // red
				levelColor.critical = "199m"  // bright red
			} else {
				reset = ""
				escape = ""
				levelColor.trace = ""
				levelColor.debug = ""
				levelColor.info = ""
				levelColor.notice = ""
				levelColor.warning = ""
				levelColor.error = ""
				levelColor.critical = ""
			}
		}
	}

	override public var defaultHashValue: Int { 1 }

	override public init() {
		super.init()
		levelColor.trace = "💜 "  // purple
		levelColor.debug = "💚 "  // green
		levelColor.info = "💙 "  // blue
		levelColor.notice = "💙 "  // blue
		levelColor.warning = "💛 "  // yellow
		levelColor.error = "❤️ "  // red
		levelColor.critical = "🔥 "  // red
	}

	// print to Xcode Console. uses full base class functionality
	override open func send(
		_ level: Logging.Logger.Level,
		msg: String,
		thread: String,
		file: String,
		function: String,
		line: Int,
		context: Logging.Logger.Metadata? = nil
	) -> String? {
		let formattedString = super.send(
			level,
			msg: msg,
			thread: thread,
			file: file,
			function: function,
			line: line,
			context: context
		)

		if let message = formattedString {
			#if os(Linux)
				print(message)
			#else
				switch logPrintWay {
				case let .logger(subsystem, category):
					_logger(
						message: message,
						level: level,
						subsystem: subsystem,
						category: category
					)
				case .nslog:
					_nslog(message: message)
				case .print:
					_print(message: message)
				}
			#endif
		}
		return formattedString
	}

	private func _logger(
		message: String,
		level: Logging.Logger.Level,
		subsystem: String,
		category: String
	) {
		#if canImport(OSLog)
			if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
				let logger = Logger(subsystem: subsystem, category: category)
				switch level {
				case .trace:
					logger.trace("\(message)")
				case .debug:
					logger.debug("\(message)")
				case .info:
					logger.info("\(message)")
				case .notice:
					logger.notice("\(message)")
				case .warning:
					logger.warning("\(message)")
				case .error:
					logger.error("\(message)")
				case .critical:
					logger.critical("\(message)")
				}
			} else {
				_print(message: message)
			}
		#else
			_print(message: message)
		#endif
	}

	private func _nslog(message: String) {
		NSLog("%@", message)
	}

	private func _print(message: String) {
		print(message)
	}
}
