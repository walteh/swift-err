# swift-err



[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

> **Elegant error handling for Swift** - Transform verbose try/catch blocks into clean, functional code with powerful error operators.

## Before vs After

**Before: Traditional Swift Error Handling**
```swift
// Verbose, nested, hard to follow
func processUserData() throws -> UserProfile {
    do {
        let userData = try fetchUserData()
        do {
            let profile = try parseUserData(userData)
            return profile
        } catch {
            print("Parse error: \(error)")
            throw error
        }
    } catch {
        print("Fetch error: \(error)")
        throw error
    }
}
```

**After: With swift-err**
```swift
// Clean, flat, easy to follow
func processUserData() throws -> UserProfile {
    var err: Error = .Empty()

    guard let userData = try fetchUserData() !> err else {
        print("Fetch error: \(err)")
        throw err
    }

    guard let profile = try parseUserData(userData) !> err else {
        print("Parse error: \(err)")
        throw err
    }

    return profile
}
```

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [The Problem](#the-problem)
- [The Solution](#the-solution)
- [Usage](#usage)
  - [Basic Error Handling (`!>`)](#basic-error-handling-)
  - [Async Error Handling (`!>>`)](#async-error-handling-)
  - [Working with Result Type](#working-with-result-type)
  - [Converting Try/Throw to Result](#converting-trythrow-to-result)
- [Functional Error Handling](#functional-error-handling)
- [Advanced Features](#advanced-features)
  - [Error Context](#error-context)
  - [Error Chaining and Inspection](#error-chaining-and-inspection)
- [Why Use swift-err?](#why-use-swift-err)
- [Real World Examples](#real-world-examples)
- [Requirements](#requirements)
- [Coming Soon](#coming-soon)
- [License](#license)
- [Contributing](#contributing)

## Overview

Swift's traditional error handling with `try`/`catch` becomes verbose and unwieldy, especially when dealing with multiple error-throwing operations. `swift-err` provides a concise, functional approach to error handling that lets you:

1. Handle errors with minimal boilerplate
2. Differentiate between error types cleanly
3. Convert try/throw functions into Result types elegantly
4. Maintain certainty about your error state and values

Think of it as bringing the best parts of Go's error handling to Swift, but with Swift's type safety and expressiveness.

## Installation

Add `swift-err` as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/walteh/swift-err.git", from: "*latest-release*")
]

targets: [
    .target(
        name: "YourTarget",
        dependencies: ["Err"]
    )
]
```

## The Problem

Swift's traditional error handling becomes problematic when you have multiple throwing operations:

```swift
// Traditional Swift error handling - verbose with multiple do-catch blocks
func processUserData(userId: String) throws -> UserProfile {
    // Approach 1: Nested do-catch blocks - gets deeply nested
    do {
        let userData = try fetchUserData(userId: userId)
        do {
            let profile = try parseUserData(data: userData)
            do {
                return try validateUserProfile(profile: profile)
            } catch {
                throw error
            }
        } catch {
            throw error
        }
    } catch {
        throw error
    }
}

// Approach 2: Sequential do-catch blocks - verbose and repetitive
func processUserData(userId: String) throws -> UserProfile {
    let userData: Data
    do {
        userData = try fetchUserData(userId: userId)
    } catch {
        throw error
    }

    let profile: UserProfile
    do {
        profile = try parseUserData(data: userData)
    } catch {
        throw error
    }

    do {
        return try validateUserProfile(profile: profile)
    } catch {
        throw error
    }
}

// Approach 3: Error type differentiation - requires manual pattern matching
func processUserData(userId: String) throws -> UserProfile {
    do {
        let userData = try fetchUserData(userId: userId)
        let profile = try parseUserData(data: userData)
        return try validateUserProfile(profile: profile)
    } catch let error as NetworkError {
        switch error {
        case .connectionFailed:
            // Handle connection failure
        case .timeout:
            // Handle timeout
        default:
            // Handle other network errors
        }
        throw error
    } catch let error as ParsingError {
        // Handle parsing errors
        throw error
    } catch {
        // Handle other errors
        throw error
    }
}
```

All these approaches are verbose, repetitive, and make your code harder to read and maintain.

## The Solution

`swift-err` solves this with its error operators:

```swift
func processUserData(userId: String) throws -> UserProfile {
    var err: Error = .Empty()

    guard let userData = try fetchUserData(userId: userId) !> err else {
        // Here we can handle specific error types
        if let networkError = err as? NetworkError {
            switch networkError {
            case .connectionFailed:
                print("Connection failed, will retry")
                // Maybe retry or take specific action
            default:
                print("Network error occurred: \(networkError)")
            }
        } else {
            print("Unknown error: \(err)")
        }
        throw err
    }

    guard let profile = try parseUserData(data: userData) !> err else {
        // We know exactly which operation failed
        throw err
    }

    guard let validatedProfile = try validateUserProfile(profile: profile) !> err else {
        // We know exactly which operation failed
        throw err
    }

    return validatedProfile
}
```

This approach is:
- Concise and readable
- Allows for specific error handling at each step
- Maintains a clear flow with guard statements
- Gives certainty about your values after each guard

## Usage

### Basic Error Handling (`!>`)

The `!>` operator captures errors in guard statements, giving you certainty about your error state:

```swift
func processData() throws -> String {
    var err: Error = .Empty() // Initialize with a default error

    guard let result = try someThrowingFunction() !> err else {
        // Here, we KNOW that err contains the actual error from someThrowingFunction
        // We can handle specific error types
        if let urlError = err as? URLError {
            if urlError.code == .notConnectedToInternet {
                // Handle specific network error
            }
        }
        throw err
    }
    // Here, we KNOW that result is valid and no error occurred
    return result
}
```

> [!NOTE]
> `Error.Empty()` is provided by the Err library to help with non-nullable error initialization.

### Async Error Handling (`!>>`)

For async functions, use the `!>>` operator:

```swift
func fetchUserData() async throws -> Data {
    var err: Error = .Empty()

    // Notice the parentheses around the async expression
    guard let (data, _) = await (try await URLSession.shared.data(from: url)) !>> err else {
        // Here, we KNOW that err contains the network error
        if let urlError = err as? URLError {
            if urlError.code == .notConnectedToInternet {
                // Handle specific network error
            }
        }
        throw err
    }

    // Here, we KNOW that data is valid and no error occurred
    return data
}
```

### Working with Result Type

The operators seamlessly integrate with Swift's Result type:

```swift
func handleResult() throws -> Data {
    var err: Error = .Empty()

    let result: Result<Data, Error> = .success(Data())
    guard let data = result !> err else {
        throw err
    }

    return data
}
```

### Converting Try/Throw to Result

One of the most powerful patterns with `swift-err` is converting traditional try/throw code into Result-based functions:

```swift
// Traditional approach with try/throw
func traditionalParse(json: String) throws -> User {
    let data = json.data(using: .utf8)!
    return try JSONDecoder().decode(User.self, from: data)
}

// Functional approach with Result
func functionalParse(json: String) -> Result<User, Error> {
    Result {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(User.self, from: data)
    }
}

// Usage with swift-err - clean error handling
func process(json: String) throws -> User {
    var err: Error = .Empty()

    guard let user = functionalParse(json: json) !> err else {
        // We can handle specific error types
        if let decodingError = err as? DecodingError {
            switch decodingError {
            case .keyNotFound(let key, _):
                print("Missing key: \(key)")
            case .valueNotFound(let type, _):
                print("Missing value for type: \(type)")
            default:
                print("Other decoding error")
            }
        } else {
            print("Unknown error: \(err)")
        }
        throw err
    }

    return user
}
```

## Functional Error Handling

`swift-err` enables a more functional approach to error handling:

```swift
// Define functions that return Results
func fetchData(userId: String) -> Result<Data, Error> {
    // Implementation
}

func parseData(data: Data) -> Result<ParsedData, Error> {
    // Implementation
}

func validateData(parsed: ParsedData) -> Result<ValidatedData, Error> {
    // Implementation
}

// Compose them together with clean error handling for each step
func processUser(userId: String) throws -> ValidatedData {
    var err: Error = .Empty()

    guard let data = fetchData(userId: userId) !> err else {
        // Handle specific fetch errors
        throw err
    }

    guard let parsed = parseData(data: data) !> err else {
        // Handle specific parse errors
        throw err
    }

    guard let validated = validateData(parsed: parsed) !> err else {
        // Handle specific validation errors
        throw err
    }

    return validated
}
```

This approach gives you:
- Clear separation of concerns
- Explicit error handling at each step
- A functional programming style with Result types
- Certainty about your values after each guard

## Advanced Features

### Error Context

`swift-err` provides a way to add context to your errors using `.ctx`:

```swift
func processUser() async throws -> User {
    var err: Error = .Empty()

    guard let data = try parseUserData() !> .ctx(&err, "Failed to parse user data") else {
        // err is automatically wrapped with context information
        // The original error is preserved as the "cause" of the context error
        throw err
    }

    return data
}
```

When using context, you can inspect the original error using the `cause(as:)` method:

```swift
func handleNetworkRequest() async throws -> Data {
    var err: Error = .Empty()

    guard let (data, _) = await (try await URLSession.shared.data(from: url)) !>> .ctx(&err, "Failed to fetch data") else {
        // Check for specific error types in the cause chain
        if let networkError = err.cause(as: URLError.self) {
            switch networkError.code {
            case .notConnectedToInternet:
                print("No internet connection")
            case .timedOut:
                print("Request timed out")
            default:
                print("Other network error: \(networkError)")
            }
        }
        throw err
    }

    return data
}
```

### Error Chaining and Inspection

With context errors, you can inspect the error chain:

```swift
// Check if an error contains a specific error type in its chain
if let networkError = err.cause(as: URLError.self) {
    // Handle network error
    print("Network error: \(networkError)")
}

// Print the full error chain
if let chainedError = error as? ErrorWithCause {
    for err in chainedError.causeErrorList() {
        print(err)
    }
}
```

## Why Use swift-err?

1. **Reduced Verbosity**: Eliminate nested do-catch blocks and repetitive error handling code
2. **Error Type Differentiation**: Easily handle different error types with standard Swift type casting
3. **Functional Approach**: Convert between try/throw and Result types elegantly
4. **Certainty**: After a guard statement, you KNOW whether you have a valid result or an error
5. **Clean Syntax**: The `!>` and `!>>` operators provide a clean, Swift-like syntax
6. **Async Support**: First-class support for async/await with proper error handling
7. **Error Isolation**: Handle errors at the function level where they occur
8. **Advanced Context**: Optional context and error chaining for more sophisticated error handling

## Real World Examples

### Multiple API Calls with Error Handling

```swift
func fetchUserProfile(userId: String) async throws -> CompleteUserProfile {
    var err: Error = .Empty()

    // Fetch basic user data
    guard let userData = await (try await fetchUserData(userId: userId)) !>> err else {
        // Handle specific network errors
        if let urlError = err as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                print("No internet connection")
            case .timedOut:
                print("Request timed out")
            default:
                print("Other URL error: \(urlError)")
            }
        }
        throw err
    }

    // Fetch user preferences
    guard let preferences = await (try await fetchUserPreferences(userId: userId)) !>> err else {
        // We know exactly which operation failed
        throw err
    }

    // Fetch user activity history
    guard let activityHistory = await (try await fetchUserActivity(userId: userId)) !>> err else {
        // We know exactly which operation failed
        throw err
    }

    // Combine all data
    return CompleteUserProfile(
        userData: userData,
        preferences: preferences,
        activityHistory: activityHistory
    )
}
```

### Converting Library Functions to Functional Style

```swift
// Original library functions that use try/throw
func libraryFetchData() throws -> Data { /* ... */ }
func libraryParseData(_ data: Data) throws -> ParsedData { /* ... */ }
func libraryProcessData(_ parsed: ParsedData) throws -> ProcessedData { /* ... */ }

// Functional wrappers
func fetchData() -> Result<Data, Error> {
    Result { try libraryFetchData() }
}

func parseData(_ data: Data) -> Result<ParsedData, Error> {
    Result { try libraryParseData(data) }
}

func processData(_ parsed: ParsedData) -> Result<ProcessedData, Error> {
    Result { try libraryProcessData(parsed) }
}

// Usage with swift-err - clean error handling
func performOperation() throws -> ProcessedData {
    var err: Error = .Empty()

    guard let data = fetchData() !> err else {
        // Handle fetch errors
        throw err
    }

    guard let parsed = parseData(data) !> err else {
        // Handle parse errors
        throw err
    }

    guard let processed = processData(parsed) !> err else {
        // Handle process errors
        throw err
    }

    return processed
}
```

## Requirements

- Swift 6.0+
- macOS 13.0+ / iOS 13.0+ / tvOS 13.0+ / watchOS 6.0+ / macCatalyst 13.0+

## Coming Soon

The following components are currently in development:

- **LogEvent**: A structured logging event system that integrates with swift-log
- **LogDistributor**: A logging distribution system for routing log events to different destinations

## License

This project is licensed under the [Apache License 2.0](LICENSE).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
