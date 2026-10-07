import AppKit
import XCTest
@testable import MacParakeet

@MainActor
final class IdlePillHitTestingTests: XCTestCase {
    private final class FlippedHost: NSView {
        override var isFlipped: Bool { true }
    }

    func testTopNubOwnsHitsInsideFlippedHostingView() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 150))
        let host = FlippedHost(frame: parent.bounds)
        parent.addSubview(host)
        let tracker = IdlePillTrackingView(frame: NSRect(x: 17, y: 23, width: 350, height: 90))
        tracker.collapsedPillRect = NSRect(x: 145, y: 66, width: 60, height: 24)
        host.addSubview(tracker)

        let nubCenter = host.convert(NSPoint(x: 175, y: 78), from: tracker)
        XCTAssertTrue(tracker.hitTest(nubCenter) === tracker)
        XCTAssertTrue(parent.hitTest(parent.convert(nubCenter, from: host)) === tracker)
        XCTAssertTrue(tracker.acceptsFirstMouse(for: nil))

        let transparentArea = host.convert(NSPoint(x: 175, y: 12), from: tracker)
        XCTAssertNil(tracker.hitTest(transparentArea))
    }

    func testBottomNubOwnsHitsInsideFlippedHostingView() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 150))
        let host = FlippedHost(frame: parent.bounds)
        parent.addSubview(host)
        let tracker = IdlePillTrackingView(frame: NSRect(x: 17, y: 23, width: 350, height: 90))
        tracker.collapsedPillRect = NSRect(x: 145, y: 0, width: 60, height: 24)
        host.addSubview(tracker)

        let nubCenter = host.convert(NSPoint(x: 175, y: 12), from: tracker)
        XCTAssertTrue(tracker.hitTest(nubCenter) === tracker)
        XCTAssertTrue(parent.hitTest(parent.convert(nubCenter, from: host)) === tracker)

        let transparentArea = host.convert(NSPoint(x: 175, y: 78), from: tracker)
        XCTAssertNil(tracker.hitTest(transparentArea))
    }
}
