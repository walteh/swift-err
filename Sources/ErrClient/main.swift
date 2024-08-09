import Err
import Foundation

func myThrowingFunc(_ arg: Int) throws -> UInt32 {
	return UInt32(arg)
}

func myThrowingAsyncFunc(_ arg: Int) async throws -> UInt32 {
	return UInt32(arg)
}

struct Hello: Error {}

@err
func checker() async -> Result<String, Error> {
	guard let res2 = try myThrowingFunc(12) else {
		return .failure(err)
	}

	guard let res3 = Result(catching: { try myThrowingFunc(12) }).err() else {
		return .failure(err)
	}

	guard let res4 = try myThrowingFunc(12) else {
		return .failure(err)
	}

	guard let res5 = try await myThrowingAsyncFunc(12) else {
		return .failure(err)
	}

	return .success("ok")
}
