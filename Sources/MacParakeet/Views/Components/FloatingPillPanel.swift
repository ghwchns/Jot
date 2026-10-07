import AppKit
import MacParakeetCore
import SwiftUI

/// Shared native drag and saved placement for the dictation and meeting pills.
@MainActor
final class FloatingPillPanel: NSPanel, NSWindowDelegate {
    private let role: FloatingPillRole
    private let takesKey: Bool
    private let defaults: UserDefaults
    private var restoringPosition = false
    private var resetObserver: NSObjectProtocol?
    private var traceMonitor: Any?

    init(role: FloatingPillRole, size: CGSize, takesKey: Bool = false, defaults: UserDefaults = .standard) {
        self.role = role
        self.takesKey = takesKey
        self.defaults = defaults
        super.init(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .borderless], backing: .buffered, defer: false
        )
        delegate = self
        // The pill's interaction view owns down/drag/up, including click completion.
        // WindowServer background dragging would bypass that lifecycle.
        isMovableByWindowBackground = false
        if FloatingPillRuntimeTrace.enabled {
            FloatingPillRuntimeTrace.start()
            traceMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) {
                [weak self] event in
                if let self, event.windowNumber == self.windowNumber || self.frame.contains(NSEvent.mouseLocation) {
                    self.trace("localMonitor", event: event)
                }
                return event
            }
        }
        resetObserver = NotificationCenter.default.addObserver(
            forName: .floatingPillPositionsDidReset, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.restorePillPosition() }
        }
    }

    deinit {
        if let resetObserver { NotificationCenter.default.removeObserver(resetObserver) }
        if let traceMonitor { NSEvent.removeMonitor(traceMonitor) }
    }

    override var canBecomeKey: Bool { takesKey }
    override var canBecomeMain: Bool { false }

    override func orderFront(_ sender: Any?) {
        super.orderFront(sender)
        trace("orderFront")
    }

    override func sendEvent(_ event: NSEvent) {
        if [.leftMouseDown, .leftMouseDragged, .leftMouseUp].contains(event.type) {
            trace("panelSendEvent", event: event)
        }
        super.sendEvent(event)
    }

    private func trace(_ stage: String, event: NSEvent? = nil) {
        guard FloatingPillRuntimeTrace.enabled else { return }
        var metadata: [String: Any] = [
            "role": role.rawValue, "panelWindowNumber": windowNumber,
            "frame": FloatingPillRuntimeTrace.rect(frame), "takesKey": takesKey,
            "isKey": isKeyWindow, "visible": isVisible, "ignoresMouseEvents": ignoresMouseEvents,
            "acceptsMouseMovedEvents": acceptsMouseMovedEvents, "styleMask": styleMask.rawValue,
            "isMovable": isMovable, "backgroundMove": isMovableByWindowBackground,
            "collectionBehavior": collectionBehavior.rawValue, "level": level.rawValue
        ]
        if let contentView { metadata["tree"] = FloatingPillRuntimeTrace.view(contentView) }
        if let event {
            metadata["mouse"] = FloatingPillRuntimeTrace.mouse(event)
            if let contentView {
                let owner = contentView.hitTest(contentView.superview?.convert(event.locationInWindow, from: nil)
                    ?? event.locationInWindow)
                metadata["rootHitOwner"] = owner.map { String(describing: type(of: $0)) } ?? "nil"
            }
        }
        FloatingPillRuntimeTrace.write(stage, metadata)
    }

    private var anchorOffset: CGPoint {
        CGPoint(
            x: frame.width / 2,
            y: role == .meeting
                ? frame.height / 2
                : (DictationOverlayPlacement.current(defaults: defaults).anchorsToTop ? frame.height : 0)
        )
    }

    func restorePillPosition() {
        let saved = FloatingPillPosition.load(for: role, defaults: defaults)
        guard let screen = NSScreen.screens.first(where: { Self.screenID($0) == saved?.screenID }) ?? NSScreen.main
        else { return }
        let usable = Self.usableFrame(screen)
        let origin: CGPoint
        if let saved {
            origin = saved.origin(in: usable, panelSize: frame.size, anchorOffset: anchorOffset)
        } else if role == .dictation {
            origin = DictationOverlayLayout.origin(
                in: usable, panelSize: frame.size, placement: DictationOverlayPlacement.current(defaults: defaults)
            )
        } else {
            origin = CGPoint(x: usable.maxX - frame.width, y: usable.midY - frame.height / 2)
        }
        restoringPosition = true
        setFrameOrigin(origin)
        restoringPosition = false
    }

    func windowDidMove(_ notification: Notification) {
        trace("windowDidMove")
        guard !restoringPosition, let screen else { return }
        FloatingPillPosition(
            screenID: Self.screenID(screen),
            anchor: CGPoint(x: frame.minX + anchorOffset.x, y: frame.minY + anchorOffset.y),
            usableFrame: Self.usableFrame(screen)
        ).save(for: role, defaults: defaults)
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

/// One mouse sequence owns a pill drag. Click actions run only on release.
/// `performDrag(with:)` returns immediately and may consume mouse-up, so it
/// cannot decide whether this same interaction was a click.
@MainActor
class FloatingPillInteractionView: NSView {
    private struct DragStart {
        let pointer: CGPoint
        let origin: CGPoint
        var moved = false
    }

    private var dragStart: DragStart?

    override var mouseDownCanMoveWindow: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        FloatingPillRuntimeTrace.write("ownerMouseDown", ["class": String(describing: type(of: self)),
            "mouse": FloatingPillRuntimeTrace.mouse(event)])
        guard let window else { return }
        dragStart = DragStart(
            pointer: window.convertPoint(toScreen: event.locationInWindow), origin: window.frame.origin)
    }

    override func mouseDragged(with event: NSEvent) {
        FloatingPillRuntimeTrace.write("ownerMouseDragged", ["class": String(describing: type(of: self)),
            "mouse": FloatingPillRuntimeTrace.mouse(event), "hasDragStart": dragStart != nil])
        guard let window, var start = dragStart else { return }
        let pointer = window.convertPoint(toScreen: event.locationInWindow)
        let delta = CGPoint(x: pointer.x - start.pointer.x, y: pointer.y - start.pointer.y)
        if delta != .zero { start.moved = true }
        dragStart = start
        window.setFrameOrigin(CGPoint(x: start.origin.x + delta.x, y: start.origin.y + delta.y))
    }

    override func mouseUp(with event: NSEvent) {
        FloatingPillRuntimeTrace.write("ownerMouseUp", ["class": String(describing: type(of: self)),
            "mouse": FloatingPillRuntimeTrace.mouse(event), "hasDragStart": dragStart != nil])
        let start = dragStart
        dragStart = nil
        guard let start, !start.moved else { return }
        pillClicked(at: convert(event.locationInWindow, from: nil))
    }

    func pillClicked(at point: CGPoint) {}
}

/// Dragging the waveform moves its native panel; end buttons retain their hits.
struct FloatingPillDragArea: NSViewRepresentable {
    private final class DragView: FloatingPillInteractionView {
        override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
    }

    func makeNSView(context: Context) -> NSView { DragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
