// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "ErrMacroMacros", type: "StringifyMacro")


@freestanding(expression)
public macro errreturn<R>(
//	_ error: Error?,
//	 _ comment: @autoclosure () -> String? = nil,
	_ expression: () throws -> R
) -> R? = #externalMacro(module: "ErrMacroMacros", type: "ErrReturnMacro")

@freestanding(expression)
public macro errreturn<R>(
//	_ error: Error?,
//	 _ comment: @autoclosure () -> String? = nil,
	_ expression: () -> Result<R, Error>
) -> R? = #externalMacro(module: "ErrMacroMacros", type: "ErrReturnMacro")


@freestanding(declaration)
public macro errreturnd<R>(
	_ error: Error?,
//	 _ comment: @autoclosure () -> String? = nil,
	_ expression: () throws -> R
) = #externalMacro(module: "ErrMacroMacros", type: "ErrReturndMacro")
