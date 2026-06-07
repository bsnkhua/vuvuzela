import SwiftUI

enum Theme {
    // Background
    static let background = Color(red: 0.04, green: 0.04, blue: 0.08)
    static let cardBackground = Color(red: 0.08, green: 0.09, blue: 0.14)
    static let cardBorder = Color(white: 1, opacity: 0.07)

    // Accent
    static let red = Color(red: 0.8, green: 0.0, blue: 0.0)
    static let blue = Color(red: 0.0, green: 0.24, blue: 0.65)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.53, green: 0.57, blue: 0.63)
    static let textDim = Color(white: 1, opacity: 0.35)

    // Qualification indicators (from ESPN API note colors)
    static let qualifyGreen = Color(red: 0.51, green: 0.84, blue: 0.67)    // #81D6AC – direct
    static let qualifyLightGreen = Color(red: 0.71, green: 0.91, blue: 0.81) // #B5E7CE – best 3rd
    static let eliminated = Color(red: 1.0, green: 0.50, blue: 0.52)         // #FF7F84

    // Live match pulse
    static let live = Color(red: 1.0, green: 0.27, blue: 0.27)

    // Tab bar
    static let tabActive = Color.white
    static let tabInactive = Color(white: 1, opacity: 0.4)
}
