import AppKit
import SwiftUI

/// The approved Jot note/speech mark for inline app surfaces.
struct BreathWaveLogo: View {
    var size: CGFloat = 18
    var tint: Color = DesignSystem.Colors.accent
    var opacity: Double = 1.0

    var body: some View {
        Image(nsImage: Self.cachedMark)
            .resizable()
            .renderingMode(.original)
            .interpolation(.high)
            .frame(width: size, height: size)
            .opacity(opacity)
            .accessibilityHidden(true)
    }

    private static let cachedMark: NSImage = BreathWaveIcon.brandMark(pointSize: 18)
}
