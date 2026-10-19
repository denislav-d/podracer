import Combine
import CoreMotion
import Foundation

@MainActor
final class HeadphoneMotionService: NSObject, ObservableObject {
    @Published private(set) var isAvailable = false
    @Published private(set) var isConnected = false
    @Published private(set) var isCalibrated = false
    @Published private(set) var authorizationStatus: CMAuthorizationStatus = .notDetermined
    @Published private(set) var relativePitch: Double = 0
    @Published private(set) var previewLane = 1
    @Published private(set) var userAcceleration = CMAcceleration()
    @Published private(set) var sensorLabel = "—"
    @Published private(set) var statusText = "Waiting for AirPods…"
    @Published private(set) var lastError: String?

    var onTap: (() -> Void)?
    var onLane: ((Int) -> Void)?

    private let manager = CMHeadphoneMotionManager()
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "PodRacer.HeadphoneMotion"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private var startingPose: CMAttitude?
    private var latestAttitude: CMAttitude?
    private var smoothedPitch: Double = 0
    private var captureOnNextSample = false
    private var tapDetector = TapDetector()
    var laneMapper = LaneMapper()

    func start() {
        authorizationStatus = CMHeadphoneMotionManager.authorizationStatus()
        isAvailable = manager.isDeviceMotionAvailable
        manager.delegate = self
        manager.startConnectionStatusUpdates()

        guard manager.isDeviceMotionAvailable else {
            statusText = "Headphone motion is not available. Use AirPods with head tracking on macOS 14+."
            return
        }

        statusText = "Connect AirPods with spatial audio / head tracking."
        manager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, error in
            Task { @MainActor in
                self?.handle(motion: motion, error: error)
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        manager.stopConnectionStatusUpdates()
    }

    func startPreview() {
        if let latestAttitude {
            applyCenter(from: latestAttitude)
            statusText = "Previewing. Tilt up for left, down for right, then calibrate when level."
        } else {
            captureOnNextSample = true
            statusText = "Waiting for a motion sample. Hold the stem toward the screen."
        }
    }

    func calibrate() {
        guard let latestAttitude else {
            lastError = "No motion sample yet. Hold the AirPod still, then try again."
            return
        }
        applyCenter(from: latestAttitude)
        isCalibrated = true
        lastError = nil
        statusText = "Calibrated. Stem at the screen — tilt up for left, down for right."
        onLane?(laneMapper.currentLane)
    }

    private func applyCenter(from attitude: CMAttitude) {
        startingPose = attitude.copy() as? CMAttitude
        smoothedPitch = 0
        relativePitch = 0
        laneMapper.reset()
        previewLane = laneMapper.currentLane
        captureOnNextSample = false
    }

    func applyKeyboardLane(delta: Int) {
        onLane?(laneMapper.nudge(delta: delta))
    }

    private func handle(motion: CMDeviceMotion?, error: Error?) {
        if let error {
            lastError = error.localizedDescription
            return
        }
        guard let motion else { return }

        authorizationStatus = CMHeadphoneMotionManager.authorizationStatus()
        isConnected = true
        lastError = nil
        userAcceleration = motion.userAcceleration
        latestAttitude = motion.attitude.copy() as? CMAttitude
        sensorLabel = Self.label(for: motion.sensorLocation)
        if captureOnNextSample, let latestAttitude {
            applyCenter(from: latestAttitude)
            statusText = "Previewing. Tilt up for left, down for right, then calibrate when level."
        }

        let relative = motion.attitude.copy() as? CMAttitude
        if let startingPose, let relative {
            relative.multiply(byInverseOf: startingPose)
            smoothedPitch = smoothedPitch * 0.35 + relative.pitch * 0.65
            relativePitch = smoothedPitch
            previewLane = laneMapper.update(pitch: smoothedPitch)
            onLane?(previewLane)
        } else {
            relativePitch = motion.attitude.pitch
        }

        if tapDetector.ingest(motion.userAcceleration) {
            onTap?()
        }
    }

    private static func label(for location: CMDeviceMotion.SensorLocation) -> String {
        switch location {
        case .headphoneLeft: "Left bud"
        case .headphoneRight: "Right bud"
        default: "Bud"
        }
    }
}

extension HeadphoneMotionService: CMHeadphoneMotionManagerDelegate {
    nonisolated func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in
            isConnected = true
            statusText = "AirPods connected. Point the stem at the screen, then calibrate."
        }
    }

    nonisolated func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in
            isConnected = false
            isCalibrated = false
            startingPose = nil
            statusText = "Motion lost. If you pulled a bud from your ear, turn off Automatic Ear Detection."
        }
    }
}
