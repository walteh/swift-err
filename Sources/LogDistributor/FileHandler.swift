//
//  FileHandler.swift
//
//
//  Created by walter on 3/7/23.
//

import Foundation
import Logging

public class FileHandler: Logging.LogHandler, @unchecked Sendable {
	public subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
		get {
			return self.metadata[key]
		}
		set(newValue) {
			self.metadata[key] = newValue
		}
	}

	public var metadata: Logging.Logger.Metadata = [:]

	public var logLevel: Logging.Logger.Level

	public let fileLogger: FileDestination

	public init(level: Logging.Logger.Level, location: URL) {
		self.logLevel = level
		self.fileLogger = .init(logFileURL: location)
		//		fileLogger.colored = true
	}

	public func log(
		level: Logger.Level,
		message: Logger.Message,
		metadata: Logger.Metadata?,
		source _: String,
		file: String,
		function: String,
		line: UInt
	) {
		// try to convert msg object to String and put it on queue
		_ = self.fileLogger.send(
			level,
			msg: message.description,
			thread: Thread.current.name ?? "unknown",
			file: file,
			function: function,
			line: Int(line),
			context: metadata
		)
	}
}
