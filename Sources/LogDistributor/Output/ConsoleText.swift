extension String {
	/// Converts this `String` to `ConsoleText`.
	///
	///     console.output("Hello, " + "world!".consoleText(color: .green))
	///
	/// See `ConsoleStyle` for more information.
	public func consoleText(_ style: ConsoleStyle = .plain) -> ConsoleText {
		[ConsoleTextFragment(string: self, style: style)]
	}

	/// Converts this `String` to `ConsoleText`.
	///
	///     console.output("Hello, " + "world!".consoleText(color: .green))
	///
	/// See `ConsoleStyle` for more information.
	public func consoleText(
		color: ConsoleColor? = nil,
		background: ConsoleColor? = nil,
		isBold: Bool = false
	) -> ConsoleText {
		let style = ConsoleStyle(color: color, background: background, isBold: isBold)
		return consoleText(style)
	}
}

/// A collection of `ConsoleTextFragment`s. Represents stylized text that can be outputted
/// to a `Console`.
///
///     let text: ConsoleText = "Hello, " + "world".consoleText(color: .green)
///
/// See `Console.output(_:newLine:)` for more information.
public struct ConsoleText: RandomAccessCollection, ExpressibleByArrayLiteral,
	ExpressibleByStringLiteral, CustomStringConvertible
{
	/// See `Collection`.
	public var startIndex: Int {
		fragments.startIndex
	}

	public var count: Int {
		fragments.reduce(0) { result, frag in
			result + frag.string.count
		}
	}

	/// See `Collection`.
	public var endIndex: Int {
		fragments.endIndex
	}

	/// See `Collection`.
	public func index(after i: Int) -> Int {
		i + 1
	}

	/// See `CustomStringConvertible`.
	public var description: String {
		fragments.map(\.string).joined()
	}

	/// See `ExpressibleByArrayLiteral`.
	public init(arrayLiteral elements: ConsoleTextFragment...) {
		fragments = elements
	}

	/// See `ExpressibleByStringLiteral`.
	public init(stringLiteral string: String) {
		if string.count > 0 {
			fragments = [.init(string: string)]
		} else {
			fragments = []
		}
	}

	/// One or more `ConsoleTextFragment`s making up this `ConsoleText.
	public var fragments: [ConsoleTextFragment]

	/// Creates a new `ConsoleText`.
	public init(fragments: [ConsoleTextFragment]) {
		self.fragments = fragments
	}

	/// See `Collection`.
	public subscript(position: Int) -> ConsoleTextFragment {
		fragments[position]
	}

	/// `\n` character with plain styling.
	@MainActor public static let newLine: ConsoleText = "\n"

	//	public func padding(toLength: Int, withPad: any StringProtocol, startingAt: Int) -> ConsoleText {
	//
	//		var me = self
	//		var raw = me.fragments.reduce("") {curr, next in
	//			return curr + next.string
	//		}
	//
	//				if toLength > 0 {
	//					// Pad to the left of the string
	//					if raw.count > toLength {
	//						// Hm... better to use suffix or prefix?
	//						return String(raw.string.prefix(toLength)).consoleText(raw.style)
	//					} else {
	//						return ("".padding(toLength: toLength - self.count, withPad: " ", startingAt: 0) + raw.string).consoleText(raw.style)
	//					}
	//				} else if toLength < 0 {
	//					// Pad to the right of the string
	//
	//					let maxLength =  -toLength
	//					return raw.string.padding(toLength: maxLength, withPad: " ", startingAt: 0).consoleText(raw.style)
	//				} else {
	//					return self
	//				}
	//	}
	//

	//	private func appendPadding(_ toLength: Int, truncating: Bool = false, right: Bool = true) -> ConsoleText {
	//		var toLength = toLength
	//		if right {
	//			toLength *= -1
	//		}
	//		if toLength > 0 {
	//			// Pad to the left of the string
	//			if self.count > toLength {
	//				// Hm... better to use suffix or prefix?
	//				return truncating ? ConsoleText(self.prefix(toLength)) : self
	//			} else {
	//				return "".padding(toLength: toLength - self.count, withPad: " ", startingAt: 0) + self
	//			}
	//		} else if toLength < 0 {
	//			// Pad to the right of the string
	//
	//			let maxLength = truncating ? -toLength : max(-toLength, self.count)
	//			return self.padding(toLength: maxLength, withPad: " ", startingAt: 0)
	//		} else {
	//			return self
	//		}
	//	}
}

// MARK: Operators

/// Appends a `ConsoleText` to another `ConsoleText`.
///
///     let text: ConsoleText = "Hello, " + "world!"
///
public func + (lhs: ConsoleText, rhs: ConsoleText) -> ConsoleText {
	ConsoleText(fragments: lhs.fragments + rhs.fragments)
}

/// Appends a `ConsoleText` to another `ConsoleText` in-place.
///
///     var text: ConsoleText = "Hello, "
///     text += "world!"
///
public func += (lhs: inout ConsoleText, rhs: ConsoleText) {
	lhs = lhs + rhs
}

extension ConsoleText: RangeReplaceableCollection {
	public init() {
		self.init(fragments: [])
	}

	public mutating func replaceSubrange<C>(_ subrange: Range<Self.Index>, with newElements: C)
	where C: Collection, Self.Element == C.Element {
		fragments.replaceSubrange(subrange, with: newElements)
	}
}

extension ConsoleText: ExpressibleByStringInterpolation {
	public init(stringInterpolation: StringInterpolation) {
		fragments = stringInterpolation.fragments
	}

	public struct StringInterpolation: StringInterpolationProtocol {
		public var fragments: [ConsoleTextFragment]

		public init(literalCapacity: Int, interpolationCount _: Int) {
			fragments = []
			fragments.reserveCapacity(literalCapacity)
		}

		public mutating func appendLiteral(_ literal: String) {
			fragments.append(.init(string: literal))
		}

		public mutating func appendInterpolation(
			_ value: String,
			style: ConsoleStyle = .plain
		) {
			fragments.append(.init(string: value, style: style))
		}

		public mutating func appendInterpolation(
			_ value: String,
			color: ConsoleColor?,
			background: ConsoleColor? = nil,
			isBold: Bool = false
		) {
			fragments.append(
				.init(
					string: value,
					style: .init(
						color: color,
						background: background,
						isBold: isBold
					)
				)
			)
		}
	}
}
