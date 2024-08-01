import ErrMacro

let a = 17
let b = 25

let (result, code) = #stringify(a + b)

print("The value \(result) was produced by the code \"\(code)\"")

import Foundation

func myThrowingFunc(_ arg: Int) throws -> UInt32 {
	return UInt32(arg)
}

struct Hello: Error {}

@err
func checker() -> Result<String, Error> {
	guard let res2 = try myThrowingFunc(12) else {
		return .failure(err)
	}

	guard let res3 = try Result({ try myThrowingFunc(12) }).get() else {
		return .failure(err)
	}

	return .success("ok")
}
