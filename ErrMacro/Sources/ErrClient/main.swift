import Err
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

	guard let res3 = try Result(catching: { try myThrowingFunc(12) }).get() else {
		return .failure(err)
	}

	return .success("ok")
}
