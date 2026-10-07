import XCTest

@testable import MacParakeetCore

final class FloatingPillPositionTests: XCTestCase {
    private let usable = CGRect(x: -1000, y: 40, width: 1000, height: 800)

    func testIdleAndRecordingPanelsKeepTheSamePillAnchor() {
        let anchor = CGPoint(x: -420, y: 700)
        let position = FloatingPillPosition(screenID: 7, anchor: anchor, usableFrame: usable)
        for size in [CGSize(width: 350, height: 90), CGSize(width: 300, height: 160)] {
            let offset = CGPoint(x: size.width / 2, y: size.height)
            let origin = position.origin(in: usable, panelSize: size, anchorOffset: offset)
            XCTAssertEqual(origin.x + offset.x, anchor.x, accuracy: 0.001)
            XCTAssertEqual(origin.y + offset.y, anchor.y, accuracy: 0.001)
        }
    }

    func testSavedAnchorScalesWhenDisplayResolutionChanges() {
        let position = FloatingPillPosition(screenID: 7, anchor: CGPoint(x: -500, y: 440), usableFrame: usable)
        let changed = CGRect(x: 0, y: 0, width: 1600, height: 1000)
        let origin = position.origin(
            in: changed, panelSize: CGSize(width: 100, height: 100), anchorOffset: CGPoint(x: 50, y: 50))
        XCTAssertEqual(origin, CGPoint(x: 750, y: 450))
    }

    func testRestorationKeepsTheEntirePanelVisibleNearEveryEdge() {
        for anchor in [CGPoint(x: -1100, y: -100), CGPoint(x: 100, y: 1000)] {
            let position = FloatingPillPosition(screenID: 7, anchor: anchor, usableFrame: usable)
            let size = CGSize(width: 300, height: 160)
            let origin = position.origin(in: usable, panelSize: size, anchorOffset: CGPoint(x: 150, y: 80))
            XCTAssertTrue(usable.contains(CGRect(origin: origin, size: size)))
        }
    }

    func testOversizedPanelUsesTheUsableFrameOrigin() {
        let position = FloatingPillPosition(screenID: 7, anchor: CGPoint(x: -500, y: 440), usableFrame: usable)
        let origin = position.origin(in: usable, panelSize: CGSize(width: 2000, height: 2000), anchorOffset: .zero)
        XCTAssertEqual(origin, usable.origin)
    }

    func testEachPillOwnsItsSavedPositionAndResetPreservesOtherPreferences() {
        withDefaults { defaults in
            let dictation = FloatingPillPosition(screenID: 7, anchor: CGPoint(x: -500, y: 440), usableFrame: usable)
            let meeting = FloatingPillPosition(screenID: 8, anchor: CGPoint(x: -300, y: 500), usableFrame: usable)
            defaults.set("input-uid", forKey: "selectedMicrophone")
            dictation.save(for: .dictation, defaults: defaults)
            meeting.save(for: .meeting, defaults: defaults)
            XCTAssertEqual(FloatingPillPosition.load(for: .dictation, defaults: defaults), dictation)
            XCTAssertEqual(FloatingPillPosition.load(for: .meeting, defaults: defaults), meeting)
            FloatingPillPosition.reset(for: .dictation, defaults: defaults)
            XCTAssertNil(FloatingPillPosition.load(for: .dictation, defaults: defaults))
            XCTAssertEqual(FloatingPillPosition.load(for: .meeting, defaults: defaults), meeting)
            FloatingPillPosition.resetAll(defaults: defaults)
            XCTAssertNil(FloatingPillPosition.load(for: .meeting, defaults: defaults))
            XCTAssertEqual(defaults.string(forKey: "selectedMicrophone"), "input-uid")
        }
    }

    func testMissingOrMalformedPositionUsesDefaultPlacement() {
        withDefaults { defaults in
            XCTAssertNil(FloatingPillPosition.load(for: .dictation, defaults: defaults))
            for data in [Data("broken".utf8), Data(#"{"screenID":7,"x":2,"y":0.5}"#.utf8)] {
                defaults.set(data, forKey: "floatingPillPosition.dictation")
                XCTAssertNil(FloatingPillPosition.load(for: .dictation, defaults: defaults))
            }
        }
    }

    private func withDefaults(_ test: (UserDefaults) -> Void) {
        let suite = "floating-pill-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        test(defaults)
    }
}
