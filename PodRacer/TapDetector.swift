import CoreMotion
import Foundation

struct TapDetector {
    var threshold: Double
    var debounce: TimeInterval
    private var lastTap: Date

    init(threshold: Double = 1.85, debounce: TimeInterval = 0.4) {
        self.threshold = threshold
        self.debounce = debounce
        lastTap = .distantPast
    }

    mutating func ingest(_ acceleration: CMAcceleration, at time: Date = .now) -> Bool {
        let magnitude = sqrt(
            acceleration.x * acceleration.x
                + acceleration.y * acceleration.y
                + acceleration.z * acceleration.z
        )
        guard magnitude >= threshold else { return false }
        guard time.timeIntervalSince(lastTap) >= debounce else { return false }
        lastTap = time
        return true
    }
}
