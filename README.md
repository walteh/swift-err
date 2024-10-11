# swift-err

swift-err is a Swift package that provides convenient error handling macros for Swift projects, allowing for more expressive and type-safe error handling.

## Features

- `@err` function macro to access thrown errors in guard else statements
- `@err_traced` includes trace information in thrown errors (file, line, function)
- Works with any function that can throw, including async functions

## Example

```swift
@err
func example() throws async -> String {
    guard let result = try await someThrowingFunction() else {
        throw err // "err" is the error thrown by someThrowingFunction
    }
    return result
}
```

## Installation

Add the following dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/walteh/swift-err.git", branch: "main")
```

Then, add "Err" to your target's dependencies:

```swift
.target(name: "YourTarget", dependencies: ["Err"]),
```

## Usage

### Basic Error Handling

Use the `@err` macro to simplify error handling in your functions:

```swift
// Without @err macro
func resultWithoutErrMacro() async -> Result<String, Error> {
    guard let res = try? await myThrowingAsyncFunc(12) else {
        // ⚠️ We have no idea what the error is
        return .failure(UnknownError())
    }
    return .success("\(res)")
}

// With @err macro
@err
func resultWithErrMacro() async -> Result<String, Error> {
    guard let res = try await myThrowingAsyncFunc(12) else {
        // ✅ "err" is the error thrown by myThrowingAsyncFunc
        switch err {
        case is ValidBusinessError:
            return .success("operation already completed")
        default:
            return .failure(err) // or "throw err" if you want to rethrow
        }
    }
    return .success("\(res)")
}
```

### Traced Error Handling

For more detailed error tracing, use the `@err_traced` macro. This wraps the error with the location (file, line, and function) where the error was triggered.

```swift
@err_traced
func tracedExample() throws -> String {
    guard let result = try someThrowingFunction() else {
        throw err // This error will include trace information
    }
    return result
}
```

## How It Works

The `@err` and `@err_traced` macros expand to code that captures the error from throwing expressions. Here's a simplified view of what the macro expansion looks like:

```swift
// Original code with @err macro
@err
func example() throws -> String {
    guard let result = try someThrowingFunction() else {
        throw err
    }
    return result
}

// Expanded code (simplified)
func example() throws -> String {
    var ___err: Error? = nil
    guard let result = Result.___err___create(catching: {
        try someThrowingFunction()
    }).___to(&___err) else {
        let err = ___err!
        throw err
    }
    return result
}
```

This expansion allows you to use `err` in your guard statements to access the thrown error, enabling more expressive error handling.

## Testing

The package includes comprehensive unit tests. Run the tests using:

```bash
swift test
```

## Requirements

- Swift 6.0+

## License

This project is licensed under the [Apache License 2.0](LICENSE).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
