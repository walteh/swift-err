// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(body)
public macro err() = #externalMacro(module: "ErrMacros", type: "Err")

public extension Result {
	func to(_ err: inout Error?) -> (Success?) {
		switch self {
		case let .success(value):
			return value
		case let .failure(error):
			err = error
			return nil
		}
	}
}
