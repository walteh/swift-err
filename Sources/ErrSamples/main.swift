import Err
import Foundation

func myThrowingFunc(_ arg: Int) throws -> UInt32 {
	return UInt32(arg)
}

func myThrowingAsyncFunc(_ arg: Int) async throws -> UInt32 {
	return UInt32(arg)
}

func myResultAsyncFunc(_ arg: Int) async -> Result<UInt32, Error> {
	return .success(UInt32(arg))
}

func myResultFunc(_ arg: Int) -> Result<UInt32, Error> {
	return .success(UInt32(arg))
}

struct Hello: Error {}

@err
func checker() async -> Result<String, Error> {
	guard let res2 = try myThrowingFunc(12) else {
		return .failure(err)
	}

	guard let res3 = myResultFunc(12).err() else {
		return .failure(err)
	}

	guard let res4 = try myThrowingFunc(12) else {
		return .failure(err)
	}

	guard let res5 = try await myThrowingAsyncFunc(12) else {
		return .failure(err)
	}

	guard let res6 = await myResultAsyncFunc(12).err() else {
		return .failure(err)
	}

	return .success("ok")
}

@err
func example() async -> Result<String, Error> {
	guard let res2 = try await myThrowingAsyncFunc(12) else {
		return .failure(err)
	}

	return .success("\(res2)")
}
