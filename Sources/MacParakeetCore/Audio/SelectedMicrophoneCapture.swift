import AVFoundation
import CoreAudio
import Foundation
import os

/// Opens a named raw microphone without AVAudioEngine's system-default aggregate.
/// Lifecycle calls belong to the microphone platform queue; sample delivery uses
/// an AVFoundation delegate queue, not the realtime audio render thread.
final class SelectedMicrophoneCapture: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, @unchecked Sendable {
    private struct State {
        var acceptingBuffers = false
        var failed = false
        var format: AVAudioFormat?
    }

    private let session = AVCaptureSession()
    private let output = AVCaptureAudioDataOutput()
    private let sampleQueue = DispatchQueue(label: "com.macparakeet.selected-microphone.samples")
    private let state = OSAllocatedUnfairLock(initialState: State())
    private let convert = CMSampleBufferToPCMBuffer()
    // A conversion failure is an invalid callback, not an engine death. Send
    // zero frames through the shared tap's existing invalid-buffer policy.
    private let invalidBuffer = AVAudioPCMBuffer(
        pcmFormat: AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1)!, frameCapacity: 1
    )!
    private let handler: @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void
    private let onFailure: @Sendable () -> Void
    private var observers: [NSObjectProtocol] = []

    let deviceUID: String
    var inputFormat: AVAudioFormat? { state.withLock { $0.format } }
    var isRunning: Bool { session.isRunning }

    init(
        deviceID: AudioDeviceID,
        handler: @escaping @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void,
        onFailure: @escaping @Sendable () -> Void
    ) throws {
        guard let uid = AudioDeviceManager.deviceUID(deviceID),
            let device = AVCaptureDevice(uniqueID: uid)
        else { throw AVAudioEngineMicrophonePlatformError.noDeviceAvailable }
        deviceUID = uid
        self.handler = handler
        self.onFailure = onFailure
        super.init()

        let input = try AVCaptureDeviceInput(device: device)
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        guard session.canAddInput(input) else {
            throw AVAudioEngineMicrophonePlatformError.noDeviceAvailable
        }
        session.addInput(input)
        output.audioSettings = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsNonInterleaved: true,
        ]
        guard session.canAddOutput(output) else {
            throw AVAudioEngineMicrophonePlatformError.noDeviceAvailable
        }
        session.addOutput(output)
        output.setSampleBufferDelegate(self, queue: sampleQueue)
        state.withLock { $0.format = AVAudioFormat(cmAudioFormatDescription: device.activeFormat.formatDescription) }
        for name in [AVCaptureSession.runtimeErrorNotification, AVCaptureSession.wasInterruptedNotification] {
            observers.append(
                NotificationCenter.default.addObserver(forName: name, object: session, queue: nil) {
                    [weak self] _ in self?.reportFailure()
                })
        }
    }

    deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
    }

    func start() {
        state.withLock {
            $0.acceptingBuffers = true; $0.failed = false
        }
        session.startRunning()
    }

    func stop() {
        state.withLock { $0.acceptingBuffers = false }
        session.stopRunning()
        // Retire queued callbacks before the platform reuses its consumers.
        sampleQueue.sync {}
        output.setSampleBufferDelegate(nil, queue: nil)
    }

    private func reportFailure() {
        let notify = state.withLock { state in
            guard state.acceptingBuffers, !state.failed else { return false }
            state.failed = true
            return true
        }
        if notify { onFailure() }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard state.withLock({ $0.acceptingBuffers && !$0.failed }) else { return }
        do {
            let buffer = try convert.makePCMBuffer(from: sampleBuffer)
            state.withLock { $0.format = buffer.format }
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let hostTimestamp =
                session.synchronizationClock.map {
                    CMSyncConvertTime(timestamp, from: $0, to: CMClockGetHostTimeClock())
                } ?? .invalid
            let hostTime =
                hostTimestamp.isNumeric
                ? CMClockConvertHostTimeToSystemUnits(hostTimestamp)
                : mach_absolute_time()
            handler(buffer, AVAudioTime(hostTime: hostTime))
        } catch {
            handler(invalidBuffer, AVAudioTime(hostTime: mach_absolute_time()))
        }
    }
}
