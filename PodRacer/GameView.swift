import SpriteKit
import SwiftUI

struct GameView: NSViewRepresentable {
    let scene: GameScene

    func makeNSView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        scene.scaleMode = .resizeFill
        if view.bounds.width > 0, view.bounds.height > 0 {
            scene.size = view.bounds.size
        }
        view.presentScene(scene)
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: SKView, context: Context) {
        if nsView.scene !== scene {
            scene.scaleMode = .resizeFill
            nsView.presentScene(scene)
        }
        if nsView.bounds.width > 0, nsView.bounds.height > 0, scene.size != nsView.bounds.size {
            scene.size = nsView.bounds.size
        }
        if nsView.window?.firstResponder !== nsView {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}
