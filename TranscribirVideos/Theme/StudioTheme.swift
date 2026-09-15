import SwiftUI

enum StudioTheme {
    static let ink = Color(red: 0.102, green: 0.090, blue: 0.071)
    static let panel = Color(red: 0.165, green: 0.141, blue: 0.110)
    static let well = Color(red: 0.129, green: 0.110, blue: 0.086)
    static let amber = Color(red: 0.910, green: 0.630, blue: 0.290)
    static let amberSoft = Color(red: 0.910, green: 0.630, blue: 0.290).opacity(0.18)
    static let paper = Color(red: 0.965, green: 0.941, blue: 0.890)
    static let paperEdge = Color(red: 0.890, green: 0.847, blue: 0.753)
    static let inkText = Color(red: 0.173, green: 0.141, blue: 0.102)
    static let muted = Color(red: 0.725, green: 0.655, blue: 0.557)
    static let cream = Color(red: 0.957, green: 0.925, blue: 0.863)

    static let displayFont: Font = .system(.largeTitle, design: .serif).weight(.medium)
    static let titleFont: Font = .system(.title2, design: .serif).weight(.medium)
    static let bodySerif: Font = .system(.body, design: .serif)
    static let mono: Font = .system(.body, design: .monospaced)
}
