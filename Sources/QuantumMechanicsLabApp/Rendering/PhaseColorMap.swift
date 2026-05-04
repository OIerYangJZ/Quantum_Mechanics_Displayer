import SwiftUI

enum PhaseColorMap {
    static func color(for phase: Double, density: Double = 1) -> Color {
        let hue = (phase + .pi) / (2 * .pi)
        return Color(hue: hue, saturation: 0.85, brightness: max(0.15, min(density, 1)))
    }
}
