import SwiftUI

struct MaterialColorScheme: Sendable {
    let primary: Color
    let onPrimary: Color
    let primaryContainer: Color
    let onPrimaryContainer: Color
    let secondary: Color
    let onSecondary: Color
    let secondaryContainer: Color
    let onSecondaryContainer: Color
    let tertiary: Color
    let onTertiary: Color
    let tertiaryContainer: Color
    let onTertiaryContainer: Color
    let error: Color
    let onError: Color
    let errorContainer: Color
    let onErrorContainer: Color
    let surface: Color
    let surfaceContainer: Color
    let surfaceContainerHigh: Color
    let surfaceContainerHighest: Color
    let onSurface: Color
    let onSurfaceVariant: Color
    let outline: Color
    let outlineVariant: Color
    let inverseSurface: Color
    let inverseOnSurface: Color

    static let light = MaterialColorScheme(
        primary: Color(hex: 0x6750A4),
        onPrimary: .white,
        primaryContainer: Color(hex: 0xEADDFF),
        onPrimaryContainer: Color(hex: 0x21005D),
        secondary: Color(hex: 0x625B71),
        onSecondary: .white,
        secondaryContainer: Color(hex: 0xE8DEF8),
        onSecondaryContainer: Color(hex: 0x1D192B),
        tertiary: Color(hex: 0x7D5260),
        onTertiary: .white,
        tertiaryContainer: Color(hex: 0xFFD8E4),
        onTertiaryContainer: Color(hex: 0x31111D),
        error: Color(hex: 0xB3261E),
        onError: .white,
        errorContainer: Color(hex: 0xF9DEDC),
        onErrorContainer: Color(hex: 0x410E0B),
        surface: Color(hex: 0xFEF7FF),
        surfaceContainer: Color(hex: 0xF3EDF7),
        surfaceContainerHigh: Color(hex: 0xECE6F0),
        surfaceContainerHighest: Color(hex: 0xE6E0E9),
        onSurface: Color(hex: 0x1D1B20),
        onSurfaceVariant: Color(hex: 0x49454F),
        outline: Color(hex: 0x79747E),
        outlineVariant: Color(hex: 0xCAC4D0),
        inverseSurface: Color(hex: 0x322F35),
        inverseOnSurface: Color(hex: 0xF5EFF7)
    )

    static let dark = MaterialColorScheme(
        primary: Color(hex: 0xD0BCFF),
        onPrimary: Color(hex: 0x381E72),
        primaryContainer: Color(hex: 0x4F378B),
        onPrimaryContainer: Color(hex: 0xEADDFF),
        secondary: Color(hex: 0xCCC2DC),
        onSecondary: Color(hex: 0x332D41),
        secondaryContainer: Color(hex: 0x4A4458),
        onSecondaryContainer: Color(hex: 0xE8DEF8),
        tertiary: Color(hex: 0xEFB8C8),
        onTertiary: Color(hex: 0x492532),
        tertiaryContainer: Color(hex: 0x633B48),
        onTertiaryContainer: Color(hex: 0xFFD8E4),
        error: Color(hex: 0xF2B8B5),
        onError: Color(hex: 0x601410),
        errorContainer: Color(hex: 0x8C1D18),
        onErrorContainer: Color(hex: 0xF9DEDC),
        surface: Color(hex: 0x141218),
        surfaceContainer: Color(hex: 0x211F26),
        surfaceContainerHigh: Color(hex: 0x2B2930),
        surfaceContainerHighest: Color(hex: 0x36343B),
        onSurface: Color(hex: 0xE6E0E9),
        onSurfaceVariant: Color(hex: 0xCAC4D0),
        outline: Color(hex: 0x938F99),
        outlineVariant: Color(hex: 0x49454F),
        inverseSurface: Color(hex: 0xE6E0E9),
        inverseOnSurface: Color(hex: 0x322F35)
    )
}

enum MaterialTypography {
    static let displaySmall = Font.system(size: 36, weight: .regular)
    static let headlineLarge = Font.system(size: 32, weight: .regular)
    static let headlineSmall = Font.system(size: 24, weight: .regular)
    static let titleLarge = Font.system(size: 22, weight: .medium)
    static let titleMedium = Font.system(size: 16, weight: .semibold)
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .regular)
    static let labelLarge = Font.system(size: 14, weight: .semibold)
    static let labelMedium = Font.system(size: 12, weight: .semibold)
}

enum MaterialShape {
    static let extraSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 28
}

private struct MaterialColorsKey: EnvironmentKey {
    static let defaultValue = MaterialColorScheme.light
}

extension EnvironmentValues {
    var materialColors: MaterialColorScheme {
        get { self[MaterialColorsKey.self] }
        set { self[MaterialColorsKey.self] = newValue }
    }
}

private struct MaterialThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let colors = colorScheme == .dark ? MaterialColorScheme.dark : .light
        content
            .environment(\.materialColors, colors)
            .tint(colors.primary)
            .foregroundStyle(colors.onSurface)
    }
}

extension View {
    func materialTheme() -> some View {
        modifier(MaterialThemeModifier())
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
