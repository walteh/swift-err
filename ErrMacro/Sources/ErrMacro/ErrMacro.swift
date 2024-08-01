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

@attached(body)
public macro err(
//	_ error: Error?,
//	 _ comment: @autoclosure () -> String? = nil,
//	_ expression: () throws -> R
) = #externalMacro(module: "ErrMacroMacros", type: "ErrMacro")
