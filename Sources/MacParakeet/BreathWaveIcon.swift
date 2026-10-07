import AppKit

/// Jot bitmap branding and adaptive menu-bar status mark.
enum BreathWaveIcon {

    /// Menu bar icon state variants.
    enum MenuBarState: Equatable {
        case idle
        case recording
        case processing
    }

    /// Load the parakeet silhouette as a **template** NSImage for menu bar use.
    /// The image is stored as a processed SwiftPM resource (menubar-icon.png / @2x).
    /// Template images adapt to light/dark mode automatically.
    static func menuBarIcon(pointSize: CGFloat = 18, state: MenuBarState = .idle) -> NSImage {
        let baseIcon = loadBaseMenuBarIcon(pointSize: pointSize)

        switch state {
        case .idle:
            return baseIcon
        case .recording:
            return compositeIcon(base: baseIcon, pointSize: pointSize, badgeColor: .systemRed)
        case .processing:
            return compositeIcon(base: baseIcon, pointSize: pointSize, badgeColor: .systemOrange)
        }
    }

    private static func loadBaseMenuBarIcon(pointSize: CGFloat) -> NSImage {
        let image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "Jot") ?? NSImage()
        image.size = NSSize(width: pointSize, height: pointSize)
        image.isTemplate = true
        return image
    }

    /// Composite the base icon with a colored status dot in the bottom-right corner.
    /// The resulting image is NOT a template (so the dot renders in color).
    /// The base icon is drawn using the menu bar's label color so it matches
    /// the idle template appearance in both light and dark mode.
    private static func compositeIcon(base: NSImage, pointSize: CGFloat, badgeColor: NSColor) -> NSImage {
        let size = NSSize(width: pointSize, height: pointSize)
        let image = NSImage(size: size, flipped: false) { rect in
            // Use the base icon alpha channel as a mask, filled with the menu bar
            // foreground color. This replicates template-image rendering while keeping
            // isTemplate=false so the colored dot isn't tinted by the system.
            // NSStatusBar items use controlTextColor which is white on dark menu bars
            // and black on light ones (pre-Sonoma or accessibility settings).
            if let cgBase = base.cgImage(forProposedRect: nil, context: nil, hints: nil),
                let ctx = NSGraphicsContext.current?.cgContext
            {
                ctx.saveGState()
                ctx.clip(to: rect, mask: cgBase)
                NSColor.controlTextColor.setFill()
                ctx.fill(rect)
                ctx.restoreGState()
            }

            // Draw colored dot (bottom-right, 5pt diameter)
            let dotSize: CGFloat = 5
            let dotRect = NSRect(
                x: rect.maxX - dotSize - 0.5,
                y: 0.5,
                width: dotSize,
                height: dotSize
            )
            badgeColor.setFill()
            NSBezierPath(ovalIn: dotRect).fill()

            return true
        }
        // NOT a template — the dot must render in color
        image.isTemplate = false
        return image
    }

    /// The approved Jot note/speech bitmap, kept in its original grayscale.
    static func brandMark(pointSize: CGFloat = 18) -> NSImage {
        let image =
            Bundle.module.url(forResource: "jot-mark", withExtension: "png")
            .flatMap { NSImage(contentsOf: $0) } ?? NSImage()
        image.size = NSSize(width: pointSize, height: pointSize)
        return image
    }
}
