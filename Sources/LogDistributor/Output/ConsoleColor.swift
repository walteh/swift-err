/// Supported colors for creating a `ConsoleStyle` for `ConsoleText`.
///
/// - note: Normal and bright colors are represented here separately instead of as a flag on `ConsoleStyle`
///         basically because "that's how ANSI colors work". It's a little conceptually weird, but so are terminal
///         control codes.
///
public enum ConsoleColor {
	case black
	case red
	case green
	case yellow
	case blue
	case magenta
	case cyan
	case white
	case brightBlack
	case brightRed
	case brightGreen
	case brightYellow
	case brightBlue
	case brightMagenta
	case brightCyan
	case brightWhite
	case palette(UInt8)
	case custom(r: UInt8, g: UInt8, b: UInt8)
	case orange
	case perrywinkle
	case brightOrange
	case lightPurple
	case lightBlue
}

extension ConsoleColor {
	/// Converts the color to the corresponding SGR color spec
	var ansiSpec: ANSISGRColorSpec {
		switch self {
		case .black: return .traditional(0)
		case .red: return .traditional(1)
		case .green: return .traditional(2)
		case .yellow: return .traditional(3)
		case .blue: return .traditional(4)
		case .magenta: return .traditional(5)
		case .cyan: return .traditional(6)
		case .white: return .traditional(7)
		case .brightBlack: return .bright(0)
		case .brightRed: return .bright(1)
		case .brightGreen: return .bright(2)
		case .brightYellow: return .bright(3)
		case .brightBlue: return .bright(4)
		case .brightMagenta: return .bright(5)
		case .brightCyan: return .bright(6)
		case .brightWhite: return .bright(7)
		case let .palette(p): return .palette(p)
		case let .custom(r, g, b): return .rgb(r: r, g: g, b: b)
		case .orange: return .palette(216)
		case .perrywinkle: return .palette(147)
		case .brightOrange: return .palette(214)
		case .lightPurple: return .palette(99)
		case .lightBlue: return .palette(33)
		}
	}
}
