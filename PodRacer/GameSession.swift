import Combine
import SpriteKit
import SwiftUI

@MainActor
final class GameSession: ObservableObject {
    enum Screen {
        case menu
        case howToPlay
        case calibrate
        case playing
        case gameOver
    }

    @Published var screen: Screen = .menu
    @Published var selectedSpeed = 2
    @Published var score = 0
    @Published var lives = 3
    @Published var trafficLevel = 2
    @Published var isPaused = false
    @Published var didBoostFlash = false

    let motion = HeadphoneMotionService()
    let scene = GameScene(size: CGSize(width: 440, height: 760))
    private let remote = RemoteCommandService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        motion.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        scene.onScore = { [weak self] value in
            DispatchQueue.main.async {
                self?.score = value
            }
        }
        scene.onLives = { [weak self] value in
            DispatchQueue.main.async {
                self?.lives = value
            }
        }
        scene.onLevel = { [weak self] value in
            DispatchQueue.main.async {
                self?.trafficLevel = value
            }
        }
        scene.onGameOver = { [weak self] value in
            DispatchQueue.main.async {
                self?.score = value
                self?.isPaused = false
                self?.screen = .gameOver
            }
        }
        scene.onBoost = { [weak self] in
            DispatchQueue.main.async {
                self?.flashBoost()
            }
        }

        motion.onLane = { [weak self] lane in
            guard let self, self.screen == .playing, !self.isPaused else { return }
            self.scene.setTargetLane(lane)
        }
        motion.onTap = { [weak self] in
            guard let self, self.screen == .playing else { return }
            self.scene.triggerBoost()
        }

        remote.onTogglePlayPause = { [weak self] in
            self?.togglePause()
        }
    }

    func startServices() {
        motion.start()
        remote.start()
    }

    func stopServices() {
        motion.stop()
        remote.stop()
    }

    func openHowToPlay() {
        screen = .howToPlay
    }

    func openCalibrate() {
        screen = .calibrate
        motion.startPreview()
    }

    func calibrateAndPlay() {
        motion.calibrate()
        guard motion.isCalibrated else { return }
        beginRun()
    }

    func playWithKeyboard() {
        motion.laneMapper.reset()
        beginRun()
    }

    func retry() {
        beginRun()
    }

    func backToMenu() {
        scene.isPaused = true
        isPaused = false
        screen = .menu
    }

    func togglePause() {
        guard screen == .playing else { return }
        isPaused.toggle()
        scene.setPaused(isPaused)
    }

    func keyboardLane(_ delta: Int) {
        motion.applyKeyboardLane(delta: delta)
        if screen == .playing {
            scene.setTargetLane(motion.laneMapper.currentLane)
        }
    }

    private func beginRun() {
        score = 0
        lives = 3
        trafficLevel = selectedSpeed
        isPaused = false
        screen = .playing
        scene.startRun(speedLevel: selectedSpeed)
    }

    private func flashBoost() {
        didBoostFlash = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            didBoostFlash = false
        }
    }
}
