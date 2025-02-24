import Foundation

extension Thread {
	public var isRunningXCTest: Bool {
		threadDictionary.allKeys
			.contains {
				($0 as? String)?
					.range(of: "XCTest", options: .caseInsensitive) != nil
			}
	}

	public var threadName: String {
		if isMainThread {
			"main"
		} else if let threadName = Thread.current.name, !threadName.isEmpty {
			threadName
		} else {
			description
		}
	}

	public var queueName: String {
		var res = ""
		if let queueName = String(validatingCString: __dispatch_queue_get_label(nil)) {
			res = queueName
		} else if let operationQueueName = OperationQueue.current?.name, !operationQueueName.isEmpty {
			res = operationQueueName
		} else if let dispatchQueueName = OperationQueue.current?.underlyingQueue?.label,
			!dispatchQueueName.isEmpty
		{
			res = dispatchQueueName
		} else {
			res = "n/a"
		}

		switch res {
		case "com.apple.main-thread":
			return "main"
		case "com.apple.NSURLSession-delegate":
			return "url-session"
		default:
			return res.replacingOccurrences(of: "com.apple.", with: "")
		}
	}
}
