// import Testing
// import _TestingInternals
// @testable import Err
import Foundation

// @_transparent
// @_alwaysEmitIntoClient
// func ccc <T>(_ value: @autoclosure @escaping () async throws -> T?, err: inout Error) async -> T? {
// 	do {
// 		return try await value()
// 	} catch let errd {
// 		err = errd
// 		return nil
// 	}
// }


// @_transparent
// @_alwaysEmitIntoClient
// func ?? <T>(_ value: @autoclosure @escaping () async throws -> T?, err: inout Error) async -> T? {
// 	do {
// 		return try await value()
// 	} catch let errd {
// 		err = errd
// 		return nil
// 	}
// }

// @_transparent
// @_alwaysEmitIntoClient
// func ~> <T>(value: @autoclosure @escaping () async -> () async throws -> T?, err: inout Error) async -> T? {
// 	do {
// 		return try await value()()
// 	} catch let errd {
// 		err = errd
// 		return nil
// 	}
// }


// // @inline(__always)
// // func ccc <T>(_ value: @autoclosure @escaping () throws -> T?, _ err: inout Error) -> T? {
// // 	do {
// // 		return try value()
// // 	} catch let errd {
// // 		err = errd
// // 		return nil
// // 	}
// // }

// func emptyError() -> Error {
// 	return NSError(domain: "", code: 0, userInfo: nil)
// }

// #catching(whatever()) else {
// 	print("error")
// }


// // Test asynchronous failure case
// // @Test("Async operator handles error case")
// func testAsyncOperatorFailureIsolated() async throws {
//     struct TestError: Error {
//         let message: String
//     }

//     var err = emptyError()
//     let result = await ccc(try await {
//         throw TestError(message: "async test error")
// 		await Task.sleep(1_000_000_000)
//         return "success"
//     }(), err: &err)

// 	let result2 = await {
//         throw TestError(message: "async test error")
// 		await Task.sleep(1_000_000_000)
//         return "success"
//     } ~> err


// 	print(result)
// 	print(err)

//     // #expect(result == nil)
//     // #expect(err is TestError)
//     // #expect((err as? TestError)?.message == "async test error")
// }
