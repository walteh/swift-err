import ErrMacro

let a = 17
let b = 25

let (result, code) = #stringify(a + b)

print("The value \(result) was produced by the code \"\(code)\"")

import Foundation

func myThrowingFunc(_ arg: Int) throws -> UInt32 {
	return UInt32(arg)
}

public extension Result {
	func to(_ err: inout Error?) -> (Success?) {
		return self.err(&err)
	}

	func err(_ err: inout Error?) -> (Success?) {
		switch self {
		case let .success(value):
			return value
		case let .failure(error):
			err = error
			return nil
		}
	}
}

struct Hello: Error {}

@err func checker() -> Result<String, Error> {
	guard let res2 = Result(catching: {
		try myThrowingFunc(12)
	}).to(&err) else {
		return .failure(err!)
	}

	
//			print(res)

	return .success("ok")
}

checker()
