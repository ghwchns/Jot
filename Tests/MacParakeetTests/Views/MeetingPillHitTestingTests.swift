import AppKit
import MacParakeetViewModels
import XCTest

@testable import MacParakeet

@MainActor
final class MeetingPillHitTestingTests: XCTestCase {
    func testDecorativeGlyphRoutesToPillDragOwnerOnFirstClick() {
        let host = PillContentView(frame: NSRect(x: 0, y: 0, width: 118, height: 150))
        let pill = MeetingRecordingAppKitPillView(viewModel: MeetingRecordingPillViewModel(), onTap: {})
        pill.frame = host.bounds
        host.addSubview(pill)
        pill.layoutSubtreeIfNeeded()

        let center = NSPoint(x: 59, y: 75)
        XCTAssertTrue(host.hitTest(center) === pill)
        XCTAssertTrue(pill.acceptsFirstMouse(for: nil))
        XCTAssertNotNil(pill.subviews.first, "The real decorative glyph must be present")
    }

    func testTransparentPanelMarginsPassThrough() {
        let host = PillContentView(frame: NSRect(x: 0, y: 0, width: 118, height: 150))
        let pill = MeetingRecordingAppKitPillView(viewModel: MeetingRecordingPillViewModel(), onTap: {})
        pill.frame = host.bounds
        host.addSubview(pill)

        XCTAssertNil(host.hitTest(NSPoint(x: 59, y: 8)))
        XCTAssertNil(host.hitTest(NSPoint(x: 59, y: 142)))
    }
}
