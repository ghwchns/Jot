import AppKit
import MacParakeetViewModels
import SwiftUI
import XCTest
@testable import MacParakeet

@MainActor
final class IdlePillHitTestingTests: XCTestCase {
    private final class FlippedHost: NSView {
        override var isFlipped: Bool { true }
    }

    func testTopNubOwnsHitsThroughProductionContentAndHostingTree() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 150))
        let host = FlippedHost(frame: parent.bounds)
        parent.addSubview(host)
        let model = IdlePillViewModel()
        model.anchorsToTop = true
        let content = IdlePillContentView(frame: NSRect(x: 17, y: 23, width: 350, height: 90), viewModel: model)
        let tracker = content.trackingView
        tracker.collapsedPillRect = NSRect(x: 145, y: 66, width: 60, height: 24)
        host.addSubview(content)
        content.layoutSubtreeIfNeeded()
        XCTAssertNotNil(content.subviews.first as? NSHostingView<IdlePillView>)

        let nubCenter = host.convert(NSPoint(x: 175, y: 78), from: tracker)
        XCTAssertTrue(content.hitTest(nubCenter) === tracker)
        XCTAssertTrue(parent.hitTest(parent.convert(nubCenter, from: host)) === tracker)
        XCTAssertTrue(tracker.acceptsFirstMouse(for: nil))

        let transparentArea = host.convert(NSPoint(x: 175, y: 12), from: tracker)
        XCTAssertNil(content.hitTest(transparentArea))
    }

    func testBottomNubOwnsHitsThroughProductionContentAndHostingTree() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 150))
        let host = FlippedHost(frame: parent.bounds)
        parent.addSubview(host)
        let content = IdlePillContentView(
            frame: NSRect(x: 17, y: 23, width: 350, height: 90), viewModel: IdlePillViewModel())
        let tracker = content.trackingView
        tracker.collapsedPillRect = NSRect(x: 145, y: 0, width: 60, height: 24)
        host.addSubview(content)
        content.layoutSubtreeIfNeeded()

        let nubCenter = host.convert(NSPoint(x: 175, y: 12), from: tracker)
        XCTAssertTrue(content.hitTest(nubCenter) === tracker)
        XCTAssertTrue(parent.hitTest(parent.convert(nubCenter, from: host)) === tracker)

        let transparentArea = host.convert(NSPoint(x: 175, y: 78), from: tracker)
        XCTAssertNil(content.hitTest(transparentArea))
    }
}
