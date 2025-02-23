
import Foundation

@inline(__always)
func ~> <T>(value: @autoclosure () async throws -> T?, err: inout Error) async -> T? {
	do {
		return try await value()
	} catch let errd {
		err = errd
		return nil
	}
}

@inline(__always)
func ~> <T>(value: @autoclosure () throws -> T?, err: inout Error) -> T? {
	do {
		return try value()
	} catch let errd {
		err = errd
		return nil
	}
}


// func emptyError() -> Error {
// 	return MyError(message: "empty error")
// }


// func myThrowingFunc(_ arg: Int) throws -> UInt32 {
// 	return UInt32(arg)
// }

// func myActualThrowingFunc(_ arg: Int) throws -> UInt32 {
// 	throw MyError(message: "my actual throwing function")
// }

// func myThrowingAsyncFunc(_ arg: Int) async throws -> UInt32 {
// 	return UInt32(arg)
// }

// func myResultAsyncFunc(_ arg: Int) async -> Result<UInt32, Error> {
// 	return .success(UInt32(arg))
// }

// func myResultFunc(_ arg: Int) -> Result<UInt32, Error> {
// 	return .success(UInt32(arg))
// }

// func myInoutFunc(_ arg: inout UInt32) -> Result<UInt32, Error> {
// 	return .success(arg)
// }

// struct Hello: Sendable, Error {

// 	func myInoutFunc(_ arg: inout UInt32) -> Result<UInt32, Error> {
// 		return .success(arg)
// 	}

// 	// func hi() -> Result<String, Error> {
// 	// 	var err: Error? = nil
// 	// 	guard let x = (try? myInoutFunc(), &err).0 else {
// 	// 		let err = err!
// 	// 		// original else block
// 	// 	}
// 	// }

// }

// func myFunctionFunc(_ arg: () throws -> UInt32) throws -> Result<UInt32, Error> {
// 	return .success(try arg())
// }



// func oldExample() async -> Result<String, Error> {
// 	let data: Data
// 	let response: URLResponse
// 	do {
// 		(data, response) = try await URLSession.shared.data(from: URL(string: "https://www.google.com")!)
// 	} catch let err {
// 		return .failure(MyError(message: "Failed to load data", root: err))
// 	}

// 	return .success("\(data) \(response)")
// }


// func newExample() async -> Result<String, Error> {
// 	var err = emptyError()
// 	guard let (data, response) = try await URLSession.shared.data(from: URL(string: "https://www.google.com")!) ~> err else {
// 		return .failure(err)
// 	}

// 	return .success("\(data) \(response)")
// }

// // func example2() async -> Result<String, Error> {
// //     return try await URLSession.shared.data(from: URL(string: "https://www.google.com")!)  ?? error("Failed to load data")
// // }


// func checker() async -> Result<String, Error> {
// 	var err = emptyError()
// 	guard let res2 = try myThrowingFunc(12) ~> err else {
// 		return .failure(err)
// 	}

// 	print(res2)

// 	guard let res3 = try myResultFunc(12).get() ~> err else {
// 		return .failure(err)
// 	}

// 	guard let res4 = try myThrowingFunc(12) ~> err else {
// 		return .failure(err)
// 	}

// 	guard let res5 = try await myThrowingAsyncFunc(12) ~> err else {
// 		return .failure(err)
// 	}

// 	guard let res6 = try await myResultAsyncFunc(12).get() ~> err else {
// 		return .failure(err)
// 	}

// 	guard let res7 = try myFunctionFunc({
// 				guard let res = try myResultFunc(12).get() ~> err else {
// 				 throw Hello()
// 			}

// 			return res
// 		}) ~> err else {
// 		return .failure(err)
// 	}

// 	return .success("\(res2) \(res3) \(res4) \(res7) \(res7) \(res7)")
// }


