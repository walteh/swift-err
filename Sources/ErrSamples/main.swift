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

func myInoutFunc(_ arg: inout UInt32) -> Result<UInt32, Error> {
	return .success(arg)
}

struct Hello: Error {}

func myFunctionFunc(_ arg: () throws -> UInt32) throws -> Result<UInt32, Error> {
	return .success(try arg())
}

// class World {
// 	@err init() throws {
// 		guard let res = try myThrowingFunc(12) else {
// 			throw err
// 		}
// 		print(res)
// 	}
// }

// start
@err
func abc() async throws -> Result<String, Error> {
	var vheck = UInt32(12)
	guard let res = try myInoutFunc(&vheck).get() else {
		return .failure(err)
	}
	return .success("\(res)")
}

// end
// func def() async throws -> Result<String, Error> {
// 	var res: UInt32; var err: Error?; do {
// 		res = try await myThrowingAsyncFunc(12)
// 	} catch {
// 		err = error
// 	}; guard let res = Result() {
// 		return .failure(err)
// 	}
// 	return .success("\(res)")
// }

// @err
// func example() async -> Result<String, Error> {
// 	guard let res2 = try await myThrowingAsyncFunc(12) else {
// 		return .failure(err)
// 	}

// 	return .success("\(res2)")
// }

@err
func checker() async -> Result<String, Error> {
	guard let res2 = try myThrowingFunc(12) else {
		return .failure(err)
	}

	guard let res3 = try myResultFunc(12).get() else {
		return .failure(err)
	}

	guard let res4 = try myThrowingFunc(12) else {
		return .failure(err)
	}

	guard let res5 = try await myThrowingAsyncFunc(12) else {
		return .failure(err)
	}

	guard let res6 = try await myResultAsyncFunc(12).get() else {
		return .failure(err)
	}

	guard
		let res7 = try myFunctionFunc({
			guard let res = try myResultFunc(12).get() else {
				throw Hello()
			}

			return res
		})
	else {
		return .failure(err)
	}

	return .success("\(res2) \(res3) \(res4) \(res5) \(res6) \(res7)")
}
