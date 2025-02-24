@attached(body)
public macro err() = #externalMacro(module: "ErrMacros", type: "Err")

@attached(body)
public macro err_traced() = #externalMacro(module: "ErrMacros", type: "ErrTraced")


// @freestanding(expression)
// public macro asyncRedirect<T>(err: inout Error, value: @Sendable @autoclosure @escaping () async throws -> T?) async -> T? = #externalMacro(module: "ErrMacros", type: "Redirect")

@freestanding(expression)
public macro redirect<T>(err: inout Error, value: @Sendable @autoclosure @escaping () throws -> T?) -> T? = #externalMacro(module: "ErrMacros", type: "Redirect")
