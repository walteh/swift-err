import Err
import Foundation

func myThrowingFunc(_ arg: Int) throws -> UInt32 {
	return UInt32(arg)
}

func myActualThrowingFunc(_ arg: Int) throws -> UInt32 {
	throw error("my actual throwing function", root: nil)
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

struct Hello: Sendable, Error {

	func myInoutFunc(_ arg: inout UInt32) -> Result<UInt32, Error> {
		return .success(arg)
	}

	// func hi() -> Result<String, Error> {
	// 	var err: Error? = nil
	// 	guard let x = (try? myInoutFunc(), &err).0 else {
	// 		let err = err!
	// 		// original else block
	// 	}
	// }

}

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
@err_traced
func abc() async throws -> Result<String, Error> {
	var vheck = UInt32(12)
	guard let res = try myInoutFunc(&vheck).get() else {
		return .failure(err)
	}
	return .success("\(res)")
}

// func def() async throws -> Result<String, Error> {
// 	let res;
// 	do {
// 		res = try await myThrowingAsyncFunc(12)
// 	} catch {
// 		return .failure(error)
// 	};
// 	return .success("\(res)")
// }

// @err
// func example() async -> Result<String, Error> {
// 	guard let res2 = try await myThrowingAsyncFunc(12) else {
// 		return .failure(err)
// 	}

// 	return .success("\(res2)")
// }

func example() async -> Result<String, Error> {
	let data: Data
	let response: URLResponse
	do {
		(data, response) = try await URLSession.shared.data(from: URL(string: "https://www.google.com")!)
	} catch let err {
		return .failure(error("Failed to load data", root: err))
	}

	return .success("\(data) \(response)")
}

// func example2() async -> Result<String, Error> {
//     return try await URLSession.shared.data(from: URL(string: "https://www.google.com")!)  ?? error("Failed to load data")
// }

@err
func checker() async -> Result<String, Error> {
	guard let res2 = try myThrowingFunc(12) else {
		return .failure(err)
	}

	print(res2)

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

	guard let res7 = try myFunctionFunc({
			guard let res = try? myResultFunc(12).get() else {
				 throw Hello()
			}

			return res
		}) else {
		return .failure(err)
	}

	return .success("\(res2) \(res3) \(res4) \(res7) \(res7) \(res7)")
}



// func hi() -> Result<UInt32, Error> {
// 	guard let res = try! (myThrowingFunc(12) ?? error("oops")).get() else {
// 		return .failure(err)
// 	}


// 	 // i want res to be "Unnillable value of myThrowingFunc(12)"
// 	return .success(res)
// }

extension Swift.Error {
	func empty() -> Self {
		return Self.self as! Self
	}
}




struct InjectableError: Error {
}

func injectableError() -> Error {
	return InjectableError()
}


func hi() async -> Result<UInt32, Error> {
	var err: Error? = nil

	 guard let res = try await myActualThrowingFunc(12) ?? err else {

		return .failure(error("oops 12", root: err))
	}

	// i want res to be "Unnillable value of myThrowingFunc(12)"
	return .success(res)
}

@err_simple
func hi2() async -> Result<UInt32, Error> {
	guard let res = try await myActualThrowingFunc(12) else {
		return .failure(error("oops", root: err))
	}

	return .success(res)
}




func main() async {
	let res = await checker()
	print(res)
}


await main()


// MARK: - Operators
// define ~> and ~~ operators


func ~> <T>(value: @autoclosure () async throws -> T?, err: inout Error?) async -> T? {
	do {
		return try await value()
	} catch let errd {
		err = error("my processed function", root: errd)
		return nil
	}
}

func ?? <T>(value: @autoclosure () throws -> T?, err: inout Error?) -> T? {
	do {
		return try value()
	} catch let errd {
		err = error("my processed function", root: errd)
		return nil
	}
}
