/// Terminal ANSI commands
enum ANSICommand {
	case eraseScreen
	case eraseLine
	case cursorUp
	case sgr([ANSISGRCommand])
}

/// Terminal ANSI Set Graphics Rendition (SGR) commands
enum ANSISGRCommand {
	/// Set Normal (all attributes off)
	case reset
	/// Bold (intense) font
	case bold
	/// Underline
	case underline
	/// Blink (not very fast)
	case slowBlink
	/// Traditional foreground color
	case foregroundColor(UInt8)
	/// Traditional bright foreground color
	case brightForegroundColor(UInt8)
	/// Palette foreground color
	case paletteForegroundColor(UInt8)
	/// RGB "true-color" foreground color
	case rgbForegroundColor(r: UInt8, g: UInt8, b: UInt8)
	/// Keep current foreground color (effective no-op)
	case defaultForegroundColor
	/// Traditional background color
	case backgroundColor(UInt8)
	/// Traditional bright background color
	case brightBackgroundColor(UInt8)
	/// Palette background color
	case paletteBackgroundColor(UInt8)
	/// RGB "true-color" background color
	case rgbBackgroundColor(r: UInt8, g: UInt8, b: UInt8)
	/// Keep current background color (effective no-op)
	case defaultBackgroundColor
}

// extension Terminal {
//    /// Performs an `ANSICommand`.
//    func command(_ command: ANSICommand) {
//        guard enableCommands else { return }
//        Swift.print(command.ansi, terminator: "")
//    }
// }

extension ConsoleText {
	/// Wraps a string in the ANSI codes indicated
	/// by the style specification
	func terminalStylize() -> String {
		return fragments
			.map { $0.string.terminalStylize($0.style) }
			.joined()
	}
}

extension String {
	/// Wraps a string in the ANSI codes indicated
	/// by the style specification
	func terminalStylize(_ style: ConsoleStyle) -> String {
		if style.color == nil, style.background == nil, !style.isBold {
			return self // No style ("plain")
		}
		return style.ansiCommand.ansi +
			self +
			ANSICommand.sgr([.reset]).ansi
	}
}

// MARK: private

private extension ANSICommand {
	/// Converts the command to its ansi code.
	var ansi: String {
		switch self {
		case .cursorUp:
			return "1A".ansi
		case .eraseScreen:
			return "2J".ansi
		case .eraseLine:
			return "2K".ansi
		case let .sgr(subcommands):
			return (subcommands.map(\.ansi).joined(separator: ";") + "m").ansi
		}
	}
}

extension ANSISGRCommand {
	/// Converts the command to its ansi code.
	var ansi: String {
		switch self {
		case .reset: return "0"
		case .bold: return "1"
		case .underline: return "4"
		case .slowBlink: return "5"
		case let .foregroundColor(c): return "3\(c)"
		case let .brightForegroundColor(c): return "9\(c)"
		case let .paletteForegroundColor(c): return "38;5;\(c)"
		case let .rgbForegroundColor(r, g, b): return "38;2;\(r);\(g);\(b)"
		case .defaultForegroundColor: return "39"
		case let .backgroundColor(c): return "4\(c)"
		case let .brightBackgroundColor(c): return "10\(c)"
		case let .paletteBackgroundColor(c): return "48;5;\(c)"
		case let .rgbBackgroundColor(r, g, b): return "48;2;\(r);\(g);\(b)"
		case .defaultBackgroundColor: return "49"
		}
	}
}

/// This type exists for the sole purpose of encapsulating
/// the logic for distinguishing between "foreground" and "background"
/// encodings of otherwise identically-specified colors.
enum ANSISGRColorSpec {
	case traditional(UInt8)
	case bright(UInt8)
	case palette(UInt8)
	case rgb(r: UInt8, g: UInt8, b: UInt8)
	case `default`
}

extension ANSISGRColorSpec {
	/// Convert the color spec to an SGR command
	var foregroundAnsiCommand: ANSISGRCommand {
		switch self {
		case let .traditional(c): return .foregroundColor(c)
		case let .bright(c): return .brightForegroundColor(c)
		case let .palette(c): return .paletteForegroundColor(c)
		case let .rgb(r, g, b): return .rgbForegroundColor(r: r, g: g, b: b)
		case .default: return .defaultForegroundColor
		}
	}

	var backgroundAnsiCommand: ANSISGRCommand {
		switch self {
		case let .traditional(c): return .backgroundColor(c)
		case let .bright(c): return .brightBackgroundColor(c)
		case let .palette(c): return .paletteBackgroundColor(c)
		case let .rgb(r, g, b): return .rgbBackgroundColor(r: r, g: g, b: b)
		case .default: return .defaultBackgroundColor
		}
	}
}

extension ConsoleStyle {
	/// The ANSI command for this console style.
	var ansiCommand: ANSICommand {
		var commands: [ANSISGRCommand] = [.reset]

		if isBold {
			commands.append(.bold)
		}
		if let color {
			commands.append(color.ansiSpec.foregroundAnsiCommand)
		}
		if let background {
			commands.append(background.ansiSpec.backgroundAnsiCommand)
		}
		return .sgr(commands)
	}
}

private extension String {
	/// Converts a String to a full ANSI command.
	var ansi: String {
		return "\u{001B}[" + self
	}
}
