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
		case .black: .traditional(0)
		case .red: .traditional(1)
		case .green: .traditional(2)
		case .yellow: .traditional(3)
		case .blue: .traditional(4)
		case .magenta: .traditional(5)
		case .cyan: .traditional(6)
		case .white: .traditional(7)
		case .brightBlack: .bright(0)
		case .brightRed: .bright(1)
		case .brightGreen: .bright(2)
		case .brightYellow: .bright(3)
		case .brightBlue: .bright(4)
		case .brightMagenta: .bright(5)
		case .brightCyan: .bright(6)
		case .brightWhite: .bright(7)
		case let .palette(p): .palette(p)
		case let .custom(r, g, b): .rgb(r: r, g: g, b: b)
		case .orange: .palette(216)
		case .perrywinkle: .palette(147)
		case .brightOrange: .palette(214)
		case .lightPurple: .palette(99)
		case .lightBlue: .palette(33)
		}
	}
}
