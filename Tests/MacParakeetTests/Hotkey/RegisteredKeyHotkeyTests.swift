import XCTest
@testable import MacParakeet
@testable import MacParakeetCore

final class RegisteredKeyHotkeyTests: XCTestCase {
    private final class Listener: RegisteredKeyHotkeyListening {
        var stops = 0
        func stop() { stops += 1 }
    }

    func testOnlyBareKeySingleTapToggleUsesRegisteredShortcut() {
        XCTAssertTrue(HotkeyManager(trigger: .fromKeyCode(96), gestureMode: .singleTapToggle).usesRegisteredKeyHotkey)
        for mode in [HotkeyGestureController.Mode.holdOnly, .doubleTapOnly, .doubleTapAndHold] {
            XCTAssertFalse(HotkeyManager(trigger: .fromKeyCode(96), gestureMode: mode).usesRegisteredKeyHotkey)
        }
        for trigger in [HotkeyTrigger.fn, .control, .chord(modifiers: ["control"], keyCode: 96)] {
            XCTAssertFalse(HotkeyManager(trigger: trigger, gestureMode: .singleTapToggle).usesRegisteredKeyHotkey)
        }
    }

    func testRegisteredF5TogglesOncePerPressAndIgnoresTapDuplicates() throws {
        let manager = HotkeyManager(trigger: .fromKeyCode(96), gestureMode: .singleTapToggle)
        let listener = Listener()
        var event: ((Bool) -> Void)?
        var starts = 0
        var stops = 0
        manager.onStartRecording = { mode in
            XCTAssertEqual(mode, .persistent)
            starts += 1
        }
        manager.onStopRecording = { stops += 1 }
        XCTAssertTrue(
            manager.startRegisteredKeyHotkey { keyCode, callback in
                XCTAssertEqual(keyCode, 96)
                event = callback
                return listener
            })
        let press = try XCTUnwrap(event)
        press(true)
        press(true)  // repeat
        let duplicate = manager.keyCodeEventDecisionForTesting(type: .keyDown, keyCode: 96, timestampMs: 1)
        XCTAssertEqual(duplicate.outputs, [])
        XCTAssertFalse(duplicate.shouldSwallow)
        XCTAssertEqual(starts, 1)
        XCTAssertEqual(stops, 0)
        press(false)
        press(true)
        press(true)
        XCTAssertEqual(starts, 1)
        XCTAssertEqual(stops, 1)
        manager.stop()
        XCTAssertEqual(listener.stops, 1)
        press(false)
        press(true)
        XCTAssertEqual(starts, 1)  // callback from a retired registration
    }

    func testStopRestartRetiresOldCallbacksAndStartsFreshTake() throws {
        let manager = HotkeyManager(trigger: .fromKeyCode(96), gestureMode: .singleTapToggle)
        var oldEvent: ((Bool) -> Void)?
        var newEvent: ((Bool) -> Void)?
        var starts = 0
        manager.onStartRecording = { _ in starts += 1 }
        XCTAssertTrue(
            manager.startRegisteredKeyHotkey { _, callback in
                oldEvent = callback
                return Listener()
            })
        try XCTUnwrap(oldEvent)(true)
        manager.stop()
        XCTAssertTrue(
            manager.startRegisteredKeyHotkey { _, callback in
                newEvent = callback
                return Listener()
            })
        try XCTUnwrap(oldEvent)(true)
        try XCTUnwrap(newEvent)(true)
        XCTAssertEqual(starts, 2)
        manager.stop()
    }

    func testRegistrationFailureDoesNotClaimWorkingShortcut() {
        let manager = HotkeyManager(trigger: .fromKeyCode(96), gestureMode: .singleTapToggle)
        XCTAssertFalse(manager.startRegisteredKeyHotkey { _, _ in nil })
    }

    func testEscapeStillCancelsRegisteredTake() throws {
        let manager = HotkeyManager(trigger: .fromKeyCode(96), gestureMode: .singleTapToggle)
        var event: ((Bool) -> Void)?
        XCTAssertTrue(
            manager.startRegisteredKeyHotkey { _, callback in
                event = callback
                return Listener()
            })
        try XCTUnwrap(event)(true)
        let escape = manager.keyCodeEventDecisionForTesting(type: .keyDown, keyCode: 53, timestampMs: 1)
        XCTAssertTrue(escape.outputs.contains(.cancelRecording))
        manager.stop()
    }
}
