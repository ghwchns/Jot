import SwiftUI

/// Centralized design tokens for consistent styling across the app.
/// Jot uses neutral gray in light and dark appearances.
enum DesignSystem {
    // MARK: - Colors

    enum Colors {
        private static func gray(_ light: Double, _ dark: Double) -> Color {
            Color(light: Color(white: light), dark: Color(white: dark))
        }

        static let accent = gray(0.30, 0.78)
        static let accentLight = gray(0.94, 0.23)
        static let accentDark = gray(0.20, 0.88)
        static let onAccent = Color(light: .white, dark: .black)
        static let background = gray(0.98, 0.11)
        static let surface = gray(1, 0.17)
        static let surfaceElevated = gray(0.96, 0.23)
        static let textPrimary = gray(0.10, 1)
        static let textSecondary = gray(0.42, 0.65)
        static let textTertiary = gray(0.61, 0.40)
        static let tintNeutral = Color.primary

        // State is also conveyed by labels, shapes, and icons.
        static let successGreen = accent
        static let warningAmber = accent
        static let errorRed = accent
        static let border = gray(0.91, 0.30)
        static let divider = gray(0.94, 0.25)
        static let rowHoverBackground = gray(0.96, 0.23)
        static let cardBackground = surface
        static let playbackTrack = Color.primary.opacity(0.08)
        static let playbackFill = accent

        // Speaker names remain the primary distinction in transcripts.
        static let transcriptSpeakerLabelAlpha: CGFloat = 0.85
        static let speakerColors: [Color] = [gray(0.25, 0.90), gray(0.40, 0.75), gray(0.50, 0.65)]
        static func speakerColor(for index: Int) -> Color { speakerColors[index % speakerColors.count] }

        static let youtubeRed = accent
        static let podcastPurple = accent
        static let xMark = accent
        static let vimeoBlue = accent
        static let facebookBlue = accent
        static let tiktokTeal = accent
        static let instagramPink = accent
        static let twitchPurple = accent

        static let pillBackground = Color.black.opacity(0.7)
        static let pillBorder = Color.white.opacity(0.15)
        static let recordingRed = accent
        static let sacredGlow = Color(white: 0.90)
        static let sacredStem = Color(white: 0.70)
        static let meetingPillBackground = Color.black.opacity(0.90)
        static let meetingPillBackgroundHover = Color(white: 0.18).opacity(0.95)
        static let meetingPillStroke = Color.white.opacity(0.08)
        static let meetingPillStrokeHover = Color.white.opacity(0.15)
        static let meetingPillText = Color.white.opacity(0.9)
        static let meetingPillBadgeBackground = Color.black.opacity(0.8)
        static let contentBackground = Color(nsColor: .textBackgroundColor)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let hero: CGFloat = 64
    }

    // MARK: - Typography

    enum Typography {
        // Headlines — .rounded design = instantly warmer
        static let heroTitle = Font.system(size: 28, weight: .bold, design: .rounded)
        static let pageTitle = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let sectionTitle = Font.system(size: 17, weight: .semibold)

        // Body — larger minimums
        static let bodyLarge = Font.system(size: 15)
        static let body = Font.system(size: 14)
        static let bodySmall = Font.system(size: 13)

        /// Transcript reading body at a user-adjustable scale (base = `bodyLarge`,
        /// 15pt). Used by the transcript detail reading surfaces; the caller is
        /// responsible for clamping `scale` to a sane range.
        static func transcriptBody(scale: Double) -> Font {
            Font.system(size: 15 * scale)
        }

        // Metadata
        static let caption = Font.system(size: 12)
        static let micro = Font.system(size: 11)

        // Monospace
        static let timestamp = Font.system(size: 12).monospacedDigit()
        static let duration = Font.system(size: 11).monospacedDigit()
        static let meetingPillStatus = Font.system(size: 13, weight: .semibold)
        static let meetingPillBadge = Font.system(size: 10, weight: .medium, design: .monospaced)
        static let meetingPillCheckmark = Font.system(size: 24, weight: .semibold)

        /// Soft rounded label used inside the dictation overlay's no-speech terminal
        /// pill (e.g. "More audio pls"). Uses `.rounded` to match the organic curves
        /// of the falling leaf + Merkaba dissolve animation, and the same family as
        /// the app's headline typography (`heroTitle`, `pageTitle`). Sized to sit
        /// naturally beside the 26pt Merkaba glyph inside a low-profile horizontal
        /// oval pill.
        static let dictationOverlayTerminalLabel = Font.system(size: 9.5, weight: .medium, design: .rounded)
    }

    // MARK: - Layout

    enum Layout {
        static let sidebarMinWidth: CGFloat = 200
        static let contentMinWidth: CGFloat = 500
        static let windowMinHeight: CGFloat = 560
        static let cornerRadius: CGFloat = 16
        static let cardCornerRadius: CGFloat = 14
        static let rowCornerRadius: CGFloat = 12
        static let dropZoneCornerRadius: CGFloat = 20
        static let buttonCornerRadius: CGFloat = 12
        static let minTouchTarget: CGFloat = 44
        static let dropZoneHeight: CGFloat = 200
        static let playbackBarHeight: CGFloat = 6
        static let videoPlayerMinWidth: CGFloat = 320
        static let videoPlayerIdealRatio: CGFloat = 0.4
        static let audioScrubberHeight: CGFloat = 44
        static let thumbnailCardMinWidth: CGFloat = 200
        static let thumbnailAspectRatio: CGFloat = 16 / 9
    }

    // MARK: - Animation

    enum Animation {
        static let selectionChange: SwiftUI.Animation = .easeInOut(duration: 0.15)
        static let hoverTransition: SwiftUI.Animation = .easeInOut(duration: 0.12)
        static let contentSwap: SwiftUI.Animation = .easeInOut(duration: 0.2)
        static let portalLift: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.7)
        static let meetingPillHover: SwiftUI.Animation = .easeOut(duration: 0.15)
    }

    // MARK: - Shadows

    enum Shadows {
        static let cardRest = ShadowStyle(color: .black.opacity(0.06), radius: 4, y: 2)
        static let cardHover = ShadowStyle(color: .black.opacity(0.10), radius: 12, y: 6)
        static let portalLift = ShadowStyle(color: .black.opacity(0.12), radius: 16, y: 8)
        static let meetingPill = ShadowStyle(color: .black.opacity(0.28), radius: 12, y: 6)
    }
}

// MARK: - Shadow Style

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let y: CGFloat

    init(color: Color, radius: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.y = y
    }
}

// MARK: - Adaptive Color Helper

extension Color {
    /// Creates a color that adapts to light/dark mode.
    init(light: Color, dark: Color) {
        self.init(
            nsColor: NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                return isDark ? NSColor(dark) : NSColor(light)
            })
    }
}

// MARK: - Shadow View Modifier

extension View {
    func cardShadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: 0, y: style.y)
    }
}
