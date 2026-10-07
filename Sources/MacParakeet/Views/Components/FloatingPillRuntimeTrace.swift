import AppKit

/// Temporary, opt-in mouse routing trace for a physical-input diagnostic build.
/// Only native widget geometry and mouse metadata are written, never user content.
@MainActor
enum FloatingPillRuntimeTrace {
    static let enabled = UserDefaults.standard.bool(forKey: "jotPillTraceEnabled")
    private static var lineCount = 0
    private static var localMonitor: Any?
    private static var globalMonitor: Any?
    private static let handle: FileHandle? = {
        guard enabled else { return nil }
        let directory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Jot/PillInput", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let path = directory.appendingPathComponent("pill-\(ProcessInfo.processInfo.processIdentifier).jsonl").path
        FileManager.default.createFile(atPath: path, contents: nil, attributes: [.posixPermissions: 0o600])
        return FileHandle(forWritingAtPath: path)
    }()

    static func write(_ stage: String, _ metadata: [String: Any] = [:]) {
        guard enabled, lineCount < 5_000, let handle else { return }
        var record = metadata
        record["stage"] = stage
        record["time"] = ProcessInfo.processInfo.systemUptime
        record["traceVersion"] = 1
        guard let data = try? JSONSerialization.data(withJSONObject: record, options: [.sortedKeys]) else { return }
        try? handle.write(contentsOf: data + Data([10]))
        lineCount += 1
    }

    static func start() {
        guard enabled, localMonitor == nil else { return }
        write("traceStart")
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseDragged, .leftMouseUp, .rightMouseDown]
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
            write("applicationLocalMouse", mouse(event))
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
            write("applicationGlobalMouse", mouse(event))
        }
    }

    static func point(_ point: CGPoint) -> [CGFloat] { [point.x, point.y] }
    static func rect(_ rect: CGRect) -> [CGFloat] { [rect.minX, rect.minY, rect.width, rect.height] }

    static func mouse(_ event: NSEvent) -> [String: Any] {
        var metadata: [String: Any] = ["type": event.type.rawValue, "windowNumber": event.windowNumber,
         "locationInWindow": point(event.locationInWindow), "pointer": point(NSEvent.mouseLocation),
         "clickCount": event.clickCount, "delta": [event.deltaX, event.deltaY],
         "pressedMouseButtons": NSEvent.pressedMouseButtons,
         "hidLeftButtonDown": CGEventSource.buttonState(.hidSystemState, button: .left),
         "sessionLeftButtonDown": CGEventSource.buttonState(.combinedSessionState, button: .left)]
        if let cgEvent = event.cgEvent {
            metadata["sourcePID"] = cgEvent.getIntegerValueField(.eventSourceUnixProcessID)
            metadata["sourceStateID"] = cgEvent.getIntegerValueField(.eventSourceStateID)
            metadata["mouseButtonNumber"] = cgEvent.getIntegerValueField(.mouseEventButtonNumber)
            metadata["cgLocation"] = point(cgEvent.location)
        }
        return metadata
    }

    static func view(_ view: NSView, depth: Int = 0) -> [String: Any] {
        ["class": String(describing: type(of: view)), "frame": rect(view.frame), "bounds": rect(view.bounds),
         "flipped": view.isFlipped, "hidden": view.isHidden, "alpha": view.alphaValue,
         "children": depth < 8 ? view.subviews.map { self.view($0, depth: depth + 1) } : []]
    }
}
