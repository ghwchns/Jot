import AppKit
import MacParakeetCore
import SwiftUI

/// Shared native drag and saved placement for the dictation and meeting pills.
@MainActor
final class FloatingPillPanel: NSPanel, NSWindowDelegate {
    private let role: FloatingPillRole
    private let takesKey: Bool
    private var restoringPosition = false
    private var resetObserver: NSObjectProtocol?

    init(role: FloatingPillRole, size: CGSize, takesKey: Bool = false) {
        self.role = role
        self.takesKey = takesKey
        super.init(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .borderless], backing: .buffered, defer: false
        )
        delegate = self
        isMovableByWindowBackground = true
        resetObserver = NotificationCenter.default.addObserver(
            forName: .floatingPillPositionsDidReset, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.restorePillPosition() }
        }
    }

    deinit {
        if let resetObserver { NotificationCenter.default.removeObserver(resetObserver) }
    }

    override var canBecomeKey: Bool { takesKey }
    override var canBecomeMain: Bool { false }

    private var anchorOffset: CGPoint {
        CGPoint(
            x: frame.width / 2,
            y: role == .meeting
                ? frame.height / 2
                : (DictationOverlayPlacement.current().anchorsToTop ? frame.height : 0)
        )
    }

    func restorePillPosition() {
        let saved = FloatingPillPosition.load(for: role)
        guard let screen = NSScreen.screens.first(where: { Self.screenID($0) == saved?.screenID }) ?? NSScreen.main
        else { return }
        let usable = Self.usableFrame(screen)
        let origin: CGPoint
        if let saved {
            origin = saved.origin(in: usable, panelSize: frame.size, anchorOffset: anchorOffset)
        } else if role == .dictation {
            origin = DictationOverlayLayout.origin(
                in: usable, panelSize: frame.size, placement: DictationOverlayPlacement.current()
            )
        } else {
            origin = CGPoint(x: usable.maxX - frame.width, y: usable.midY - frame.height / 2)
        }
        restoringPosition = true
        setFrameOrigin(origin)
        restoringPosition = false
    }

    func windowDidMove(_ notification: Notification) {
        guard !restoringPosition, let screen else { return }
        FloatingPillPosition(
            screenID: Self.screenID(screen),
            anchor: CGPoint(x: frame.minX + anchorOffset.x, y: frame.minY + anchorOffset.y),
            usableFrame: Self.usableFrame(screen)
        ).save(for: role)
    }

    private static func screenID(_ screen: NSScreen) -> UInt32 {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }

    private static func usableFrame(_ screen: NSScreen) -> CGRect {
        DictationOverlayLayout.usableFrame(
            screenFrame: screen.frame, visibleFrame: screen.visibleFrame,
            topInset: max(NSStatusBar.system.thickness, screen.safeAreaInsets.top)
        )
    }
}

/// Dragging the waveform moves its native panel; end buttons retain their hits.
struct FloatingPillDragArea: NSViewRepresentable {
    private final class DragView: NSView {
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
        override func mouseDown(with event: NSEvent) { window?.performDrag(with: event) }
        override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
    }

    func makeNSView(context: Context) -> NSView { DragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
