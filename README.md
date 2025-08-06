> [!CAUTION]
> This project is experimental and not sufficiently tested.


# swift-err

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Leverage `guard` to make Swift error handling similar to Go, but with extra safety. Introduces the `!>` and `!>>` operators.


> [!NOTE]
> The primary purpose of this project was to try and see how far I could push the syntactic sugar of Swift to more closely mimic the error handling of Go.

## Quick Start

```swift
import Err

func processUser(id: String) -> Result<User, Error> {
    var err: Error = .nil  // Required: initialize an error (Error.nil is provided for convenience)

    guard let data = try fetchUserData(id) !> err else {
		// 'err' is guaranteed to be any thrown error from the try
        // because of 'guard' we MUST return from this function
		return .failure(err)
    }

    return .success(user)
}

func processUserAsync(id: String) async -> Result<User, Error> {
    var err: Error = .nil

	// for async calls, use the '!>>' operator
	// unfortunately, the double await and extra parens are also required most of the time
    guard let data = await (try await fetchUserData(id)) !>> err else {
		return .failure(err)
    }

    return .success(user)
}
```

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/walteh/swift-err.git", branch: "v3")
]
```

## Type Safety with Guard

The operators leverage Swift's `guard` statements for type safety:

```swift
func processData() -> Result<String, Error> {
    var err: Error = .nil

    guard let result = try parseData() !> err else {
        // Compiler guarantees we MUST handle the error case
        // After this point, execution cannot continue
        return .failure(err)
    }

    // Compiler guarantees 'result' is valid here
    // The guard statement provides definitive type safety
    return .success(result)
}
```

The `guard` pattern ensures:
- **Definitive error handling**: You must handle the error case
- **Type certainty**: After the guard, your value is guaranteed valid
- **Early returns**: Failed operations exit immediately


## Error Context

Optionally wrap errors with caller info and a message using `Error.wrap`:

```swift
throw err.wrap("loading user from database")
```

Also supported by the operators using `.wrap(&err, "")` syntax:

```swift
guard let result = try parseData() !> .wrap(&err, "Failed parsing") else {
    // err contains original error + your context message
    print(err)
	// to get the actual error, you can call the cause() function
	throw err.cause()
}
```

By default, wrapped errors include caller info (file name, line, function) plus your message.

To disable caller info globally:
```swift
disableCallerInfo()
```


## License

Licensed under the [Apache License 2.0](LICENSE).
