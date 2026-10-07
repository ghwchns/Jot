import AppKit
import SwiftUI
import MacParakeetCore
import MacParakeetViewModels

// MARK: - Mouse Tracking (click-aware)

/// NSView overlay that detects mouse hover and clicks for the idle pill.
/// Uses mouseMoved to precisely track whether the cursor is over the pill region,
/// not the entire panel. The hover rect changes based on expanded state.
final class IdlePillTrackingView: FloatingPillInteractionView {
    var onEnter: (() -> Void)?
    var onExit: (() -> Void)?
    var onClicked: (() -> Void)?

    /// Small rect for the collapsed pill (hover trigger zone).
    var collapsedPillRect: NSRect = .zero
    /// Larger rect for the expanded pill + tooltip (stays hovered while interacting).
    var expandedPillRect: NSRect = .zero

    private var isInsidePill = false
    private var isExpanded = false

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(
            NSTrackingArea(
                rect: bounds,
                options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
                owner: self
            ))
    }

    override func mouseEntered(with event: NSEvent) {
        // Panel entered — start tracking position
    }

    override func mouseExited(with event: NSEvent) {
        // Left the panel entirely — always exit hover
        if isInsidePill {
            isInsidePill = false
            isExpanded = false
            onExit?()
        }
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let activeRect = isExpanded ? expandedPillRect : collapsedPillRect

        if activeRect.contains(point) {
            if !isInsidePill {
                isInsidePill = true
                isExpanded = true
                onEnter?()
            }
        } else {
            if isInsidePill {
                isInsidePill = false
                isExpanded = false
                onExit?()
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let activeRect = isExpanded ? expandedPillRect : collapsedPillRect
        guard activeRect.contains(point) else { return }
        super.mouseDown(with: event)
    }

    override func pillClicked(at point: CGPoint) {
        let activeRect = isExpanded ? expandedPillRect : collapsedPillRect
        if activeRect.contains(point) { onClicked?() }
    }

    // Only intercept clicks in the visible pill region; pass through everywhere else.
    override func hitTest(_ point: NSPoint) -> NSView? {
        let activeRect = isExpanded ? expandedPillRect : collapsedPillRect
        // AppKit passes a point in the superview's coordinates. The hosting
        // view is flipped, while this tracker uses native bottom-up coordinates.
        return activeRect.contains(convert(point, from: superview)) ? self : nil
    }
}

/// The native interaction owner sits outside SwiftUI's hosting hit router.
/// SwiftUI draws the pill; this root routes its visible surface to the tracker.
final class IdlePillContentView: NSView {
    let trackingView: IdlePillTrackingView

    init(frame: NSRect, viewModel: IdlePillViewModel) {
        trackingView = IdlePillTrackingView(frame: NSRect(origin: .zero, size: frame.size))
        super.init(frame: frame)
        let hosting = NSHostingView(rootView: IdlePillView(viewModel: viewModel))
        hosting.frame = bounds
        hosting.autoresizingMask = [.width, .height]
        trackingView.autoresizingMask = [.width, .height]
        addSubview(hosting)
        addSubview(trackingView)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func hitTest(_ point: NSPoint) -> NSView? {
        trackingView.hitTest(convert(point, from: superview))
    }
}

// MARK: - Idle Pill Controller

/// Manages the persistent idle pill panel — always visible when not dictating.
/// Non-activating NSPanel that never steals focus.
@MainActor
final class IdlePillController {
    private var panel: FloatingPillPanel?
    private var trackingView: IdlePillTrackingView?

    private let viewModel: IdlePillViewModel

    init(viewModel: IdlePillViewModel) {
        self.viewModel = viewModel
    }

    func show() {
        if panel != nil { return }

        let panelWidth: CGFloat = 350
        let panelHeight: CGFloat = 90
        let content = IdlePillContentView(
            frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight), viewModel: viewModel)

        let panel = FloatingPillPanel(role: .dictation, size: CGSize(width: panelWidth, height: panelHeight))
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = content

        // Mouse tracking overlay for hover + click
        let tracker = content.trackingView
        tracker.onEnter = { [weak self] in
            Task { @MainActor in self?.viewModel.isHovered = true }
        }
        tracker.onExit = { [weak self] in
            Task { @MainActor in self?.viewModel.isHovered = false }
        }
        tracker.onClicked = { [weak self] in
            Task { @MainActor in self?.viewModel.onStartDictation?() }
        }

        trackingView = tracker
        self.panel = panel
        reposition()

        panel.orderFront(nil)
    }

    func reposition() {
        guard let panel, let trackingView else { return }
        let placement = DictationOverlayPlacement.current()
        viewModel.anchorsToTop = placement.anchorsToTop

        // Hover zones hug the anchored edge: the nub (48×10 + targeting slack)
        // collapsed, and the pill + tooltip once expanded.
        let panelSize = panel.frame.size
        func edgeRect(width: CGFloat, height: CGFloat) -> NSRect {
            NSRect(
                x: (panelSize.width - width) / 2,
                y: placement.anchorsToTop ? panelSize.height - height : 0,
                width: width,
                height: height
            )
        }
        trackingView.collapsedPillRect = edgeRect(width: 60, height: 24)
        trackingView.expandedPillRect = edgeRect(width: 320, height: 80)

        panel.restorePillPosition()
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
        trackingView = nil
    }
}
