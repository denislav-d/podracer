import AppKit
import QuartzCore
import SpriteKit

final class GameScene: SKScene {
    var onScore: ((Int) -> Void)?
    var onLives: ((Int) -> Void)?
    var onLevel: ((Int) -> Void)?
    var onGameOver: ((Int) -> Void)?
    var onBoost: (() -> Void)?

    private let laneCount = 3
    private let maxLives = 3
    private var player: SKSpriteNode?
    private var targetLane = 1
    private var score = 0
    private var lives = 3
    private var trafficLevel = 1
    private var boostRemaining: TimeInterval = 0
    private var hitCooldown: TimeInterval = 0
    private var spawnRemaining: TimeInterval = 1.8
    private var sceneryRemaining: TimeInterval = 0.6
    private var lastUpdateTime: TimeInterval = 0
    private var stripeOffset: CGFloat = 0
    private var isRunning = false
    private var worldNode: SKNode?

    func startRun(speedLevel: Int = 2) {
        removeAllChildren()
        backgroundColor = SKColor(calibratedRed: 0.07, green: 0.08, blue: 0.16, alpha: 1)
        targetLane = 1
        score = 0
        lives = maxLives
        trafficLevel = max(1, min(3, speedLevel))
        boostRemaining = 0
        hitCooldown = 0
        spawnRemaining = TrafficPace.forLevel(trafficLevel).spawnInterval
        sceneryRemaining = 0.4
        lastUpdateTime = 0
        stripeOffset = 0
        isRunning = true
        isPaused = false
        buildWorld()
        spawnPlayer()
        onScore?(0)
        onLives?(lives)
        onLevel?(trafficLevel)
    }

    func setTargetLane(_ lane: Int) {
        targetLane = max(0, min(laneCount - 1, lane))
    }

    func triggerBoost() {
        guard isRunning, !isPaused else { return }
        boostRemaining = max(boostRemaining, 0.85)
        onBoost?()
        player?.color = SKColor(calibratedRed: 1, green: 0.86, blue: 0.2, alpha: 1)
        player?.colorBlendFactor = 0.45
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard isRunning else { return }
        layoutWorld()
        player?.position.x = laneX(targetLane)
        player?.position.y = playerY
    }

    override func update(_ currentTime: TimeInterval) {
        guard isRunning else { return }
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        guard dt < 0.25 else { return }

        let speed = currentSpeed

        if boostRemaining > 0 {
            boostRemaining -= dt
            if boostRemaining <= 0 {
                restorePlayerLook()
            }
        }
        if hitCooldown > 0 {
            hitCooldown -= dt
            if hitCooldown <= 0 {
                restorePlayerLook()
            }
        }

        movePlayer(dt: dt)
        scrollStripes(speed: speed, dt: dt)
        moveNamed("traffic", speed: speed, dt: dt) { _ in
            self.score += 1
            self.onScore?(self.score)
        }
        moveNamed("scenery", speed: speed, dt: dt, onExit: nil)
        resolveHits()

        spawnRemaining -= dt
        if spawnRemaining <= 0 {
            spawnTraffic()
            spawnRemaining = TrafficPace.forLevel(trafficLevel).spawnInterval
        }

        sceneryRemaining -= dt
        if sceneryRemaining <= 0 {
            spawnScenery()
            sceneryRemaining = 0.55
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123, 0:
            setTargetLane(targetLane - 1)
        case 124, 2:
            setTargetLane(targetLane + 1)
        case 49:
            triggerBoost()
        default:
            break
        }
    }

    private func resolveHits() {
        guard isRunning, hitCooldown <= 0, let player else { return }
        let playerBox = player.frame.insetBy(dx: 14, dy: 16)
        var hitNode: SKNode?
        enumerateChildNodes(withName: "traffic") { node, stop in
            if playerBox.intersects(node.frame.insetBy(dx: 14, dy: 16)) {
                hitNode = node
                stop.pointee = true
            }
        }
        guard let hitNode else { return }
        hitNode.removeFromParent()
        lives = max(0, lives - 1)
        onLives?(lives)
        hitCooldown = 0.9
        player.color = SKColor(calibratedRed: 0.95, green: 0.28, blue: 0.28, alpha: 1)
        player.colorBlendFactor = 0.55
        if lives <= 0 {
            finishRun()
        }
    }

    private func finishRun() {
        guard isRunning else { return }
        isRunning = false
        player?.color = SKColor(calibratedRed: 0.9, green: 0.2, blue: 0.2, alpha: 1)
        player?.colorBlendFactor = 0.7
        onGameOver?(score)
    }

    private func spawnPlayer() {
        let body = SKSpriteNode(texture: PixelAssets.playerCar)
        body.position = CGPoint(x: laneX(targetLane), y: playerY)
        body.zPosition = 10
        body.name = "player"
        body.texture?.filteringMode = .nearest
        addChild(body)
        player = body
    }

    private func spawnTraffic() {
        var lanes = Array(0..<laneCount)
        lanes.shuffle()
        let count = trafficLevel >= 3 ? Int.random(in: 1...2) : 1
        for index in 0..<count {
            addCar(lane: lanes[index])
        }
    }

    private func addCar(lane: Int) {
        let texture = PixelAssets.trafficCars.randomElement() ?? PixelAssets.trafficRed
        let car = SKSpriteNode(texture: texture)
        car.texture?.filteringMode = .nearest
        car.position = CGPoint(x: laneX(lane), y: size.height + 50)
        car.zPosition = 8
        car.name = "traffic"
        addChild(car)
    }

    private func spawnScenery() {
        guard size.width >= 80, size.height >= 80 else { return }
        let texture: SKTexture = Bool.random() ? PixelAssets.cactus : PixelAssets.rock
        let node = SKSpriteNode(texture: texture)
        node.texture?.filteringMode = .nearest
        node.name = "scenery"
        node.zPosition = 3
        let left = Bool.random()
        let roadLeft = size.width * 0.11
        let roadRight = size.width * 0.89
        let leftX = random(from: 16, to: roadLeft, fallback: 20)
        let rightX = random(from: roadRight, to: size.width - 16, fallback: max(size.width - 20, 24))
        node.position = CGPoint(
            x: left ? leftX : rightX,
            y: size.height + 40
        )
        addChild(node)
    }

    private func movePlayer(dt: TimeInterval) {
        guard let player else { return }
        let destination = laneX(targetLane)
        let remaining = destination - player.position.x
        player.position.x += remaining * min(1, CGFloat(dt) * 22)
        player.position.y = playerY
        if hitCooldown > 0 {
            player.alpha = 0.5 + 0.5 * CGFloat(sin(CACurrentMediaTime() * 18))
        } else {
            player.alpha = 1
        }
    }

    private func moveNamed(_ name: String, speed: CGFloat, dt: TimeInterval, onExit: ((SKNode) -> Void)?) {
        enumerateChildNodes(withName: name) { node, _ in
            node.position.y -= speed * CGFloat(dt)
            if node.position.y < -90 {
                node.removeFromParent()
                onExit?(node)
            }
        }
    }

    private func buildWorld() {
        let world = SKNode()
        world.name = "world"
        addChild(world)
        worldNode = world
        layoutWorld()
    }

    private func layoutWorld() {
        guard let worldNode else { return }
        guard size.width >= 80, size.height >= 80 else { return }
        worldNode.removeAllChildren()

        let sky = SKSpriteNode(color: SKColor(calibratedRed: 0.08, green: 0.09, blue: 0.18, alpha: 1), size: size)
        sky.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sky.zPosition = -4
        worldNode.addChild(sky)

        let sand = SKSpriteNode(color: SKColor(calibratedRed: 0.18, green: 0.14, blue: 0.11, alpha: 1), size: CGSize(width: size.width, height: size.height))
        sand.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sand.zPosition = -3
        sand.alpha = 0.55
        worldNode.addChild(sand)

        let moon = SKSpriteNode(texture: PixelAssets.moon)
        moon.texture?.filteringMode = .nearest
        moon.position = CGPoint(x: size.width * 0.84, y: size.height * 0.86)
        moon.zPosition = -2
        worldNode.addChild(moon)

        for _ in 0..<14 {
            let star = SKSpriteNode(texture: PixelAssets.star)
            star.texture?.filteringMode = .nearest
            star.position = CGPoint(
                x: random(from: 20, to: size.width - 20, fallback: size.width / 2),
                y: random(from: size.height * 0.45, to: size.height - 20, fallback: size.height * 0.7)
            )
            star.zPosition = -2
            star.alpha = CGFloat.random(in: 0.4...1)
            worldNode.addChild(star)
        }

        let roadWidth = size.width * 0.62
        let tilesX = Int(ceil(roadWidth / PixelAssets.asphalt.size().width)) + 1
        let tilesY = Int(ceil((size.height + 40) / PixelAssets.asphalt.size().height)) + 1
        let asphaltSize = PixelAssets.asphalt.size()
        for ty in 0..<tilesY {
            for tx in 0..<tilesX {
                let tile = SKSpriteNode(texture: PixelAssets.asphalt)
                tile.texture?.filteringMode = .nearest
                tile.position = CGPoint(
                    x: (size.width - roadWidth) / 2 + asphaltSize.width * (CGFloat(tx) + 0.5),
                    y: asphaltSize.height * (CGFloat(ty) + 0.5) - 20
                )
                tile.zPosition = 0
                worldNode.addChild(tile)
            }
        }

        for divider in 1..<laneCount {
            let x = (laneX(divider - 1) + laneX(divider)) / 2
            for i in 0..<16 {
                let dash = SKSpriteNode(texture: PixelAssets.stripe)
                dash.texture?.filteringMode = .nearest
                dash.name = "stripe"
                dash.position = CGPoint(x: x, y: CGFloat(i) * 56 + stripeOffset)
                dash.zPosition = 2
                worldNode.addChild(dash)
            }
        }
    }

    private func scrollStripes(speed: CGFloat, dt: TimeInterval) {
        stripeOffset -= speed * CGFloat(dt)
        if stripeOffset < -56 { stripeOffset += 56 }
        enumerateChildNodes(withName: "//stripe") { node, _ in
            node.position.y -= speed * CGFloat(dt)
            if node.position.y < -40 {
                node.position.y += 56 * 16
            }
        }
    }

    private func restorePlayerLook() {
        guard hitCooldown <= 0 else { return }
        if boostRemaining > 0 {
            player?.color = SKColor(calibratedRed: 1, green: 0.86, blue: 0.2, alpha: 1)
            player?.colorBlendFactor = 0.45
        } else {
            player?.colorBlendFactor = 0
            player?.color = .white
        }
    }

    private var currentSpeed: CGFloat {
        let base = TrafficPace.forLevel(trafficLevel).speed
        return boostRemaining > 0 ? base * 1.28 : base
    }

    private var playerY: CGFloat {
        max(90, size.height * 0.18)
    }

    private func laneX(_ lane: Int) -> CGFloat {
        let span = size.width * 0.42
        let start = (size.width - span) / 2
        let step = span / CGFloat(laneCount - 1)
        return start + step * CGFloat(lane)
    }

    private func random(from lower: CGFloat, to upper: CGFloat, fallback: CGFloat) -> CGFloat {
        guard lower <= upper else { return fallback }
        return CGFloat.random(in: lower...upper)
    }
}

private enum TrafficPace {
    case level1
    case level2
    case level3

    static func forLevel(_ level: Int) -> TrafficPace {
        switch level {
        case 3: .level3
        case 2: .level2
        default: .level1
        }
    }

    var speed: CGFloat {
        switch self {
        case .level1: 110
        case .level2: 185
        case .level3: 270
        }
    }

    var spawnInterval: TimeInterval {
        switch self {
        case .level1: 1.85
        case .level2: 1.25
        case .level3: 0.9
        }
    }
}
