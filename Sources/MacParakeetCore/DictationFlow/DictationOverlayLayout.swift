import Foundation

/// Screen edge for the idle dictation pill and the live overlay. Both surfaces
/// share it so recording starts exactly where the idle nub sat.
public enum DictationOverlayPlacement: String, CaseIterable, Hashable, Sendable {
    case bottom
    case top

    public var displayTitle: String {
        switch self {
        case .bottom: return "Bottom"
        case .top: return "Top"
        }
    }

    public var anchorsToTop: Bool { self == .top }

    public static func current(defaults: UserDefaults = .standard) -> DictationOverlayPlacement {
        guard let raw = defaults.string(forKey: UserDefaultsAppRuntimePreferences.dictationOverlayPlacementKey),
            let placement = DictationOverlayPlacement(rawValue: raw)
        else {
            return .bottom
        }
        return placement
    }
}

/// Geometry for parking a dictation panel centered on the chosen screen edge.
public enum DictationOverlayLayout {
    public static let margin: CGFloat = 12

    /// The region a dictation panel may occupy. `visibleFrame` already clears
    /// the Dock and a shown menu bar, but it reaches the top edge when the menu
    /// bar auto-hides or an app is full screen. The menu bar (or notch) then
    /// slides over a top-anchored pill, so the top always reserves that height.
    public static func usableFrame(
        screenFrame: CGRect,
        visibleFrame: CGRect,
        topInset: CGFloat
    ) -> CGRect {
        let maxY = min(visibleFrame.maxY, screenFrame.maxY - topInset)
        return CGRect(
            x: visibleFrame.minX,
            y: visibleFrame.minY,
            width: visibleFrame.width,
            height: max(0, maxY - visibleFrame.minY)
        )
    }

    public static func origin(
        in usableFrame: CGRect,
        panelSize: CGSize,
        placement: DictationOverlayPlacement,
        margin: CGFloat = margin
    ) -> CGPoint {
        let x = usableFrame.midX - panelSize.width / 2
        let y: CGFloat
        switch placement {
        case .bottom:
            y = usableFrame.minY + margin
        case .top:
            y = max(usableFrame.minY, usableFrame.maxY - panelSize.height - margin)
        }
        return CGPoint(x: x, y: y)
    }
}

public enum FloatingPillRole: String, Sendable {
    case dictation
    case meeting
}

/// A screen-relative pill anchor, independent of its current panel size.
public struct FloatingPillPosition: Codable, Equatable, Sendable {
    public let screenID: UInt32
    public let x: Double
    public let y: Double

    public init(screenID: UInt32, anchor: CGPoint, usableFrame: CGRect) {
        self.screenID = screenID
        x = min(1, max(0, (anchor.x - usableFrame.minX) / max(1, usableFrame.width)))
        y = min(1, max(0, (anchor.y - usableFrame.minY) / max(1, usableFrame.height)))
    }

    public func origin(in usableFrame: CGRect, panelSize: CGSize, anchorOffset: CGPoint) -> CGPoint {
        let proposed = CGPoint(
            x: usableFrame.minX + x * usableFrame.width - anchorOffset.x,
            y: usableFrame.minY + y * usableFrame.height - anchorOffset.y
        )
        return CGPoint(
            x: min(max(proposed.x, usableFrame.minX), max(usableFrame.minX, usableFrame.maxX - panelSize.width)),
            y: min(max(proposed.y, usableFrame.minY), max(usableFrame.minY, usableFrame.maxY - panelSize.height))
        )
    }

    public static func load(for role: FloatingPillRole, defaults: UserDefaults = .standard) -> Self? {
        guard let data = defaults.data(forKey: key(role)),
            let position = try? JSONDecoder().decode(Self.self, from: data),
            position.x.isFinite, position.y.isFinite,
            (0...1).contains(position.x), (0...1).contains(position.y)
        else { return nil }
        return position
    }

    public func save(for role: FloatingPillRole, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.key(role))
    }

    public static func reset(for role: FloatingPillRole, defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key(role))
    }

    public static func resetAll(defaults: UserDefaults = .standard) {
        reset(for: .dictation, defaults: defaults)
        reset(for: .meeting, defaults: defaults)
        NotificationCenter.default.post(name: .floatingPillPositionsDidReset, object: nil)
    }

    private static func key(_ role: FloatingPillRole) -> String { "floatingPillPosition.\(role.rawValue)" }
}

extension Notification.Name {
    public static let floatingPillPositionsDidReset = Notification.Name("macparakeet.floatingPillPositionsDidReset")
}
