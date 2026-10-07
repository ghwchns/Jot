import AppKit
import MacParakeetCore
import MacParakeetViewModels
import SwiftUI
import XCTest

@testable import MacParakeet

/// Dispatches to real production views in never-shown panels; no OS input is posted.
@MainActor
final class FloatingPillInteractionTests: XCTestCase {
    func testIdleClickWaitsForReleaseAndDragNeverStartsDictation() throws {
        try withDefaults { defaults in
            let panel = FloatingPillPanel(role: .dictation, size: CGSize(width: 350, height: 90), defaults: defaults)
            let tracker = IdlePillTrackingView(frame: NSRect(origin: .zero, size: panel.frame.size))
            tracker.collapsedPillRect = NSRect(x: 145, y: 66, width: 60, height: 24)
            panel.contentView = tracker
            var clicks = 0
            tracker.onClicked = { clicks += 1 }
            try checkClickAndDrag(owner: tracker, panel: panel, point: CGPoint(x: 175, y: 78), clicks: { clicks })
        }
    }

    func testMeetingClickWaitsForReleaseAndDragNeverOpensItsPanel() throws {
        try withDefaults { defaults in
            let panel = FloatingPillPanel(role: .meeting, size: CGSize(width: 118, height: 150), defaults: defaults)
            let host = PillContentView(frame: NSRect(origin: .zero, size: panel.frame.size))
            var clicks = 0
            let pill = MeetingRecordingAppKitPillView(
                viewModel: MeetingRecordingPillViewModel(), onTap: { clicks += 1 })
            pill.frame = host.bounds
            host.addSubview(pill)
            panel.contentView = host
            try checkClickAndDrag(owner: pill, panel: panel, point: CGPoint(x: 59, y: 75), clicks: { clicks })
        }
    }

    func testLiveSwiftUIRepresentableOwnsMovementWithoutBackgroundDragging() throws {
        try withDefaults { defaults in
            let panel = FloatingPillPanel(role: .dictation, size: CGSize(width: 100, height: 30), defaults: defaults)
            let host = NSHostingView(rootView: FloatingPillDragArea().frame(width: 100, height: 30))
            panel.contentView = host
            host.layoutSubtreeIfNeeded()
            let owner = try XCTUnwrap(findInteractionView(in: host))
            XCTAssertFalse(owner.mouseDownCanMoveWindow)
            XCTAssertTrue(panel.isMovable, "AppKit must retain display-reconfiguration relocation")
            XCTAssertFalse(panel.isMovableByWindowBackground)
            XCTAssertTrue(owner.acceptsFirstMouse(for: nil))
            let origin = panel.frame.origin
            try drag(owner, in: panel, from: CGPoint(x: 50, y: 15), by: CGPoint(x: 80, y: 45))
            XCTAssertEqual(panel.frame.origin, CGPoint(x: origin.x + 80, y: origin.y + 45))
        }
    }

    func testIdleMovementRestoresSharedAnchorInNewRecordingPanelAndResetRestoresDefaults() throws {
        try withDefaults { defaults in
            defaults.set("top", forKey: UserDefaultsAppRuntimePreferences.dictationOverlayPlacementKey)
            defaults.set("preserved-input", forKey: "selectedMicrophone")
            let idle = FloatingPillPanel(role: .dictation, size: CGSize(width: 350, height: 90), defaults: defaults)
            idle.restorePillPosition()
            let defaultOrigin = idle.frame.origin
            let tracker = IdlePillTrackingView(frame: NSRect(origin: .zero, size: idle.frame.size))
            tracker.collapsedPillRect = tracker.bounds
            idle.contentView = tracker
            try drag(tracker, in: idle, from: CGPoint(x: 175, y: 78), by: CGPoint(x: -40, y: -120))
            let saved = try XCTUnwrap(FloatingPillPosition.load(for: .dictation, defaults: defaults))
            let recording = FloatingPillPanel(
                role: .dictation, size: CGSize(width: 300, height: 160), defaults: defaults)
            recording.restorePillPosition()
            XCTAssertEqual(recording.frame.midX, idle.frame.midX, accuracy: 0.001)
            XCTAssertEqual(recording.frame.maxY, idle.frame.maxY, accuracy: 0.001)
            XCTAssertEqual(FloatingPillPosition.load(for: .dictation, defaults: defaults), saved)

            FloatingPillPosition.resetAll(defaults: defaults)
            XCTAssertNil(FloatingPillPosition.load(for: .dictation, defaults: defaults))
            XCTAssertEqual(idle.frame.origin, defaultOrigin)
            XCTAssertEqual(defaults.string(forKey: "selectedMicrophone"), "preserved-input")
        }
    }

    func testMeetingMovementRestoresInNewPanelWithoutChangingDictationPosition() throws {
        try withDefaults { defaults in
            let panel = FloatingPillPanel(role: .meeting, size: CGSize(width: 118, height: 150), defaults: defaults)
            panel.restorePillPosition()
            let pill = MeetingRecordingAppKitPillView(viewModel: MeetingRecordingPillViewModel(), onTap: {})
            panel.contentView = pill
            try drag(pill, in: panel, from: CGPoint(x: 59, y: 75), by: CGPoint(x: -100, y: 40))
            XCTAssertNotNil(FloatingPillPosition.load(for: .meeting, defaults: defaults))
            XCTAssertNil(FloatingPillPosition.load(for: .dictation, defaults: defaults))
            let relaunched = FloatingPillPanel(role: .meeting, size: panel.frame.size, defaults: defaults)
            relaunched.restorePillPosition()
            XCTAssertEqual(relaunched.frame.origin.x, panel.frame.origin.x, accuracy: 0.001)
            XCTAssertEqual(relaunched.frame.origin.y, panel.frame.origin.y, accuracy: 0.001)
        }
    }

    private func checkClickAndDrag(
        owner: FloatingPillInteractionView, panel: FloatingPillPanel, point: CGPoint, clicks: () -> Int
    ) throws {
        let pointer = panel.convertPoint(toScreen: owner.convert(point, to: nil))
        owner.mouseDown(with: try event(.leftMouseDown, screenPoint: pointer, panel: panel))
        XCTAssertEqual(clicks(), 0, "Mouse-down must not hide or replace the panel")
        owner.mouseUp(with: try event(.leftMouseUp, screenPoint: pointer, panel: panel))
        XCTAssertEqual(clicks(), 1)
        let origin = panel.frame.origin
        owner.mouseDown(with: try event(.leftMouseDown, screenPoint: pointer, panel: panel))
        let movedPointer = CGPoint(x: pointer.x + 120, y: pointer.y - 60)
        owner.mouseDragged(with: try event(.leftMouseDragged, screenPoint: movedPointer, panel: panel))
        XCTAssertEqual(panel.frame.origin, CGPoint(x: origin.x + 120, y: origin.y - 60))
        // Returning to the start remains a drag, rather than launching an action.
        owner.mouseDragged(with: try event(.leftMouseDragged, screenPoint: pointer, panel: panel))
        owner.mouseUp(with: try event(.leftMouseUp, screenPoint: pointer, panel: panel))
        XCTAssertEqual(panel.frame.origin, origin)
        XCTAssertEqual(clicks(), 1)
    }

    private func drag(
        _ owner: FloatingPillInteractionView, in panel: FloatingPillPanel, from point: CGPoint, by delta: CGPoint
    ) throws {
        let start = panel.convertPoint(toScreen: owner.convert(point, to: nil))
        let end = CGPoint(x: start.x + delta.x, y: start.y + delta.y)
        owner.mouseDown(with: try event(.leftMouseDown, screenPoint: start, panel: panel))
        owner.mouseDragged(with: try event(.leftMouseDragged, screenPoint: end, panel: panel))
        owner.mouseUp(with: try event(.leftMouseUp, screenPoint: end, panel: panel))
    }

    private func event(_ type: NSEvent.EventType, screenPoint: CGPoint, panel: NSWindow) throws -> NSEvent {
        try XCTUnwrap(
            NSEvent.mouseEvent(
                with: type, location: panel.convertPoint(fromScreen: screenPoint), modifierFlags: [], timestamp: 0,
                windowNumber: panel.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1
            ))
    }

    private func findInteractionView(in view: NSView) -> FloatingPillInteractionView? {
        if let owner = view as? FloatingPillInteractionView { return owner }
        return view.subviews.lazy.compactMap { self.findInteractionView(in: $0) }.first
    }

    private func withDefaults(_ test: (UserDefaults) throws -> Void) throws {
        let suite = "floating-pill-interaction-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try test(defaults)
    }
}
