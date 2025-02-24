# Err

A Swift guard error operator 🫡

## Overview

`swift-err` solves a common limitation in Swift's error handling - the inability to access thrown errors in guard statements. Using the `!>` and `!>>` operators, you can elegantly handle errors while maintaining their context.

## Installation

Add Err as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/walteh/swift-err.git", from: "****check-latest-release-version****")
]

targets: [
    .target(
        name: "YourTarget",
        dependencies: ["swift-err"]
    )
]
```

## Usage

### Basic Error Handling (!>)

The `!>` operator lets you capture errors in guard statements:

```swift
func processData() throws -> String {
    var err = Error.empty // Initialize with a default error

    guard let result = try someThrowingFunction() !> err else {
        // err now contains the actual error from someThrowingFunction
        throw err
    }

    return result
}
```


> [!NOTE]
> `Error.empty` is a constant provided by the Err library to help with non-nullable error initialization.

### Async Error Handling (!>>)

For async functions, use the `!>>` operator. Note: Parentheses and two `await`s are required for the async expression (this is a Swift limitation):

```swift
func fetchUserData() async throws -> Data {
    var err: Error = Error.empty

    // Notice the parentheses around the async expression
    guard let (data, _) = await (try await URLSession.shared.data(from: url)) !>> err else {
        throw err  // err contains the network error if the request failed
    }

    return data
}
```

### Enhanced Error Context

Add context to your errors using `.apply`:

```swift
func processUser() async throws -> User {
    var err: Error = Error.empty

    guard let data = try parseUserData() !> .apply(&err, "Failed to parse user data") else {
        // err will be wrapped in an ContextError with your message and the original error
        throw err
    }

    return data
}
```

`ContextError` is a simple error type provided by `swift-err` that includes, the origional error (`cause`), the caller info (`caller`), and the provided message (`message`).

### Working with Result Type

The operators seamlessly integrate with Swift's Result type:

```swift
func handleResult() throws -> Data {
    var err: Error = Error.empty

    let result: Result<Data, Error> = .success(Data())
    guard let data = result !> err else {
        throw err
    }

    return data
}
```

### Async Result Type

We have also included an extension to the Result type to allow creation with an async function.

```swift
let result = await Result<Data, Error> {
    let data = try await someThrowingAsyncFunction()
    return data
}
```

## Why Use Err?

1. **Access Thrown Errors**: Finally, you can access the actual error thrown in guard statements
2. **Clean Syntax**: The `!>` and `!>>` operators provide a clean, Swift-like syntax
3. **Async Support**: First-class support for async/await with proper error handling
4. **Type Safety**: Maintains Swift's strong type system
5. **Context Addition**: Ability to add context to errors while preserving the original error

## Real World Example

Here's a complete example showing how Err makes error handling more ergonomic:

```swift
func processUserData() async throws -> UserProfile {
    var err: Error = Error.empty

    // Fetch user data
    guard let (userData, _) = await (try await URLSession.shared.data(from: userURL)) !>> .apply(&err, "Failed to fetch user data") else {
        throw err
    }

    // Parse the data
    guard let profile = try JSONDecoder().decode(UserProfile.self, from: userData) !> .apply(&err, "Failed to parse user profile") else {
        throw err
    }

    return profile
}
```

## Requirements

- Swift 6.0+

## License

This project is licensed under the [Apache License 2.0](LICENSE).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
