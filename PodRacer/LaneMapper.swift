import Foundation

struct LaneMapper {
    let laneCount: Int
    /// Radians of tilt-up/down from the calibrated stem-to-screen pose.
    let enterThreshold: Double
    let exitThreshold: Double
    /// When false, tilt up is left and tilt down is right.
    var invertSteer: Bool
    private(set) var currentLane: Int

    init(
        laneCount: Int = 3,
        enterThreshold: Double = 0.16,
        exitThreshold: Double = 0.07,
        invertSteer: Bool = false
    ) {
        self.laneCount = laneCount
        self.enterThreshold = enterThreshold
        self.exitThreshold = exitThreshold
        self.invertSteer = invertSteer
        currentLane = laneCount / 2
    }

    mutating func reset() {
        currentLane = laneCount / 2
    }

    /// `pitch` is relative to calibration. Positive pitch means the bud is tilted up.
    mutating func update(pitch: Double) -> Int {
        let up = invertSteer ? -pitch : pitch
        let last = laneCount - 1

        if up >= enterThreshold {
            currentLane = 0
        } else if up <= -enterThreshold {
            currentLane = last
        } else if abs(up) <= exitThreshold {
            currentLane = 1
        }

        return currentLane
    }

    mutating func nudge(delta: Int) -> Int {
        currentLane = max(0, min(laneCount - 1, currentLane + delta))
        return currentLane
    }
}
