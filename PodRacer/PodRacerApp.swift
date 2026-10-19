import SwiftUI

@main
struct PodRacerApp: App {
    @StateObject private var session = GameSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
        }
        .defaultSize(width: 440, height: 760)
        .windowResizability(.contentSize)
    }
}
