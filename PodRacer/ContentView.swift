import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: GameSession

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.07, blue: 0.09)
                .ignoresSafeArea()

            switch session.screen {
            case .menu:
                MenuScreen()
            case .howToPlay:
                HowToPlayScreen()
            case .calibrate:
                CalibrateScreen()
            case .playing, .gameOver:
                PlayScreen()
            }
        }
        .frame(minWidth: 440, minHeight: 760)
        .onAppear {
            session.startServices()
        }
        .onDisappear {
            session.stopServices()
        }
    }
}

private struct MenuScreen: View {
    @EnvironmentObject private var session: GameSession

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("PODRACER")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("MAIN MENU")
                .font(.caption.weight(.bold))
                .tracking(4)
                .foregroundStyle(.cyan)

            Image(nsImage: PixelAssets.playerCarImage)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 110)

            statusCard
            speedPicker

            Button("Play with AirPods") {
                session.openCalibrate()
            }
            .buttonStyle(GameButtonStyle())

            Button("Play with keyboard") {
                session.playWithKeyboard()
            }
            .buttonStyle(GameButtonStyle(emphasized: false))

            Button("How to play") {
                session.openHowToPlay()
            }
            .buttonStyle(GameButtonStyle(emphasized: false))

            Spacer()
        }
        .padding()
    }

    private var speedPicker: some View {
        VStack(spacing: 10) {
            Text("TRAFFIC SPEED")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 8) {
                speedButton(1, title: "Slow")
                speedButton(2, title: "Normal")
                speedButton(3, title: "Fast")
            }
        }
        .padding(14)
        .frame(maxWidth: 360)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }

    private func speedButton(_ level: Int, title: String) -> some View {
        let selected = session.selectedSpeed == level
        return Button {
            session.selectedSpeed = level
        } label: {
            VStack(spacing: 2) {
                Text("\(level)")
                    .font(.title2.weight(.heavy))
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? Color.cyan : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(selected ? Color.black : Color.white)
        }
        .buttonStyle(.plain)
    }

    private var statusCard: some View {
        VStack(spacing: 6) {
            HStack {
                Circle()
                    .fill(session.motion.isConnected ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(session.motion.isConnected ? "Motion connected · \(session.motion.sensorLabel)" : "Motion idle")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Text(session.motion.statusText)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            if let error = session.motion.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.9))
            }
        }
        .padding(14)
        .frame(maxWidth: 360)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct HowToPlayScreen: View {
    @EnvironmentObject private var session: GameSession

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("How to play")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 8) {
                labelRow("1", "Pair AirPods with head tracking")
                labelRow("2", "Turn off Automatic Ear Detection")
                labelRow("3", "Point the stem at the screen")
                labelRow("Tilt", "Up = left lane, down = right lane")
                labelRow("Tap", "Tap the bud to boost")
                labelRow("Hearts", "Each crash costs 1 of 3 lives")
                labelRow("Speed", "Pick Slow, Normal, or Fast on the menu")
                labelRow("A / D", "Keyboard fallback")
                labelRow("Space", "Boost without AirPods")
            }
            .padding(16)
            .frame(maxWidth: 360, alignment: .leading)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))

            Button("Back to menu") {
                session.backToMenu()
            }
            .buttonStyle(GameButtonStyle())
            Spacer()
        }
        .padding()
    }

    private func labelRow(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(key)
                .font(.caption.weight(.bold))
                .foregroundStyle(.cyan)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

private struct CalibrateScreen: View {
    @EnvironmentObject private var session: GameSession

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Hold your grip")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Point the stem straight at the Mac screen and keep the bud level. That pose is center. After calibrate: tilt the AirPod up for the left lane, down for the right lane.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.72))
                .frame(maxWidth: 340)

            HStack(spacing: 16) {
                tiltHint(title: "UP", subtitle: "Left lane")
                tiltHint(title: "LEVEL", subtitle: "Center")
                tiltHint(title: "DOWN", subtitle: "Right lane")
            }

            VStack(spacing: 10) {
                Text(session.motion.isConnected ? "Live tilt" : "No motion yet")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text(laneName(session.motion.previewLane))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.cyan)
                Text(String(format: "%+.0f°  %@", session.motion.relativePitch * 180 / .pi, session.motion.relativePitch >= 0 ? "up" : "down"))
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                Text(session.motion.statusText)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(18)
            .frame(maxWidth: 360)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))

            Toggle("Swap up / down", isOn: invertBinding)
                .tint(.cyan)
                .foregroundStyle(.white)
                .frame(maxWidth: 360)

            if let error = session.motion.lastError {
                Text(error)
                    .foregroundStyle(.orange)
            }

            Button("Calibrate and play") {
                session.calibrateAndPlay()
            }
            .buttonStyle(GameButtonStyle())
            .disabled(!session.motion.isConnected && !session.motion.isAvailable)

            Button("Back") {
                session.backToMenu()
            }
            .buttonStyle(GameButtonStyle(emphasized: false))
            Spacer()
        }
        .padding()
    }

    private var invertBinding: Binding<Bool> {
        Binding(
            get: { session.motion.laneMapper.invertSteer },
            set: { session.motion.laneMapper.invertSteer = $0 }
        )
    }

    private func tiltHint(title: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.cyan)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(width: 90)
        .padding(.vertical, 8)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private func laneName(_ lane: Int) -> String {
        switch lane {
        case 0: "LEFT"
        case 2: "RIGHT"
        default: "CENTER"
        }
    }
}

private struct PlayScreen: View {
    @EnvironmentObject private var session: GameSession

    var body: some View {
        ZStack {
            GameView(scene: session.scene)

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SCORE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(session.score)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: index < session.lives ? "heart.fill" : "heart")
                                .foregroundStyle(index < session.lives ? Color.red : Color.white.opacity(0.28))
                        }
                    }
                    .font(.title3)
                    speedChip
                    Spacer()
                    connectionChip
                }
                .padding(16)

                if !session.motion.isConnected {
                    Text("AirPods motion dropped — keyboard still works")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.orange.opacity(0.9), in: Capsule())
                        .foregroundStyle(.black)
                }

                Spacer()
            }

            if session.isPaused {
                overlayCard(title: "Paused", detail: "Stem press or click Resume") {
                    Button("Resume") { session.togglePause() }
                        .buttonStyle(GameButtonStyle())
                    Button("Menu") { session.backToMenu() }
                        .buttonStyle(GameButtonStyle(emphasized: false))
                }
            }

            if session.screen == .gameOver {
                overlayCard(title: "Out of hearts", detail: "Hit 3 cars · Score \(session.score)") {
                    Button("Retry") { session.retry() }
                        .buttonStyle(GameButtonStyle())
                    Button("Menu") { session.backToMenu() }
                        .buttonStyle(GameButtonStyle(emphasized: false))
                }
            }

            if session.didBoostFlash {
                Color.yellow.opacity(0.08).ignoresSafeArea()
            }
        }
        .focusable()
        .onKeyPress(.leftArrow) {
            session.keyboardLane(-1)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            session.keyboardLane(1)
            return .handled
        }
        .onKeyPress("a") {
            session.keyboardLane(-1)
            return .handled
        }
        .onKeyPress("d") {
            session.keyboardLane(1)
            return .handled
        }
        .onKeyPress(.space) {
            session.scene.triggerBoost()
            return .handled
        }
        .onKeyPress("p") {
            session.togglePause()
            return .handled
        }
    }

    private var speedChip: some View {
        let level = session.trafficLevel
        let color: Color = {
            switch level {
            case 3: .red
            case 2: .yellow
            default: .green
            }
        }()
        return Text("SPEED \(level)")
            .font(.caption.weight(.heavy))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.9), in: Capsule())
            .foregroundStyle(.black)
    }

    private var connectionChip: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(session.motion.isConnected ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(session.motion.isConnected ? session.motion.sensorLabel : "Keyboard")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.35), in: Capsule())
    }

    @ViewBuilder
    private func overlayCard(title: String, detail: String, @ViewBuilder actions: () -> some View) -> some View {
        VStack(spacing: 14) {
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text(detail)
                .foregroundStyle(.white.opacity(0.7))
            actions()
        }
        .padding(28)
        .frame(maxWidth: 280)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 20))
        .foregroundStyle(.white)
    }
}

private struct GameButtonStyle: ButtonStyle {
    var emphasized = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: 360)
            .padding(.vertical, 12)
            .background(
                emphasized
                    ? Color.cyan.opacity(configuration.isPressed ? 0.7 : 1)
                    : Color.white.opacity(configuration.isPressed ? 0.08 : 0.12),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .foregroundStyle(emphasized ? Color.black : Color.white)
    }
}
