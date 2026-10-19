import AppKit
import SpriteKit

enum PixelAssets {
    static let playerCarImage = image(rearCarPixels(
        body: NSColor(srgbRed: 0.24, green: 0.88, blue: 0.95, alpha: 1),
        highlight: NSColor(srgbRed: 0.62, green: 0.96, blue: 1, alpha: 1),
        shade: NSColor(srgbRed: 0.12, green: 0.52, blue: 0.62, alpha: 1),
        glass: NSColor(srgbRed: 0.22, green: 0.42, blue: 0.58, alpha: 1),
        shine: NSColor(srgbRed: 0.78, green: 0.92, blue: 1, alpha: 1),
        light: NSColor(srgbRed: 1, green: 0.32, blue: 0.28, alpha: 1)
    ), scale: 5)

    static let playerCar = texture(from: playerCarImage)

    static let trafficRed = sprite(frontCarPixels(
        body: NSColor(srgbRed: 0.89, green: 0.23, blue: 0.23, alpha: 1),
        highlight: NSColor(srgbRed: 1, green: 0.48, blue: 0.42, alpha: 1),
        shade: NSColor(srgbRed: 0.55, green: 0.10, blue: 0.12, alpha: 1),
        glass: NSColor(srgbRed: 0.18, green: 0.32, blue: 0.48, alpha: 1),
        shine: NSColor(srgbRed: 0.72, green: 0.88, blue: 1, alpha: 1),
        light: NSColor(srgbRed: 1, green: 0.92, blue: 0.55, alpha: 1)
    ), scale: 5)

    static let trafficOrange = sprite(frontCarPixels(
        body: NSColor(srgbRed: 0.94, green: 0.54, blue: 0.12, alpha: 1),
        highlight: NSColor(srgbRed: 1, green: 0.74, blue: 0.32, alpha: 1),
        shade: NSColor(srgbRed: 0.62, green: 0.30, blue: 0.06, alpha: 1),
        glass: NSColor(srgbRed: 0.18, green: 0.32, blue: 0.48, alpha: 1),
        shine: NSColor(srgbRed: 0.72, green: 0.88, blue: 1, alpha: 1),
        light: NSColor(srgbRed: 1, green: 0.95, blue: 0.63, alpha: 1)
    ), scale: 5)

    static let trafficPurple = sprite(frontCarPixels(
        body: NSColor(srgbRed: 0.61, green: 0.36, blue: 1, alpha: 1),
        highlight: NSColor(srgbRed: 0.80, green: 0.62, blue: 1, alpha: 1),
        shade: NSColor(srgbRed: 0.35, green: 0.16, blue: 0.68, alpha: 1),
        glass: NSColor(srgbRed: 0.18, green: 0.32, blue: 0.48, alpha: 1),
        shine: NSColor(srgbRed: 0.72, green: 0.88, blue: 1, alpha: 1),
        light: NSColor(srgbRed: 1, green: 0.78, blue: 0.92, alpha: 1)
    ), scale: 5)

    static let asphalt = sprite(asphaltPixels(), scale: 4)
    static let stripe = sprite(stripePixels(), scale: 4)
    static let cactus = sprite(cactusPixels(), scale: 4)
    static let rock = sprite(rockPixels(), scale: 4)
    static let moon = sprite(moonPixels(), scale: 5)
    static let star = sprite(starPixels(), scale: 3)

    static let trafficCars = [trafficRed, trafficOrange, trafficPurple]

    private static func sprite(_ art: ([String], [Character: NSColor]), scale: Int = 4) -> SKTexture {
        texture(from: image(art, scale: scale))
    }

    private static func texture(from image: NSImage) -> SKTexture {
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    static func image(_ art: ([String], [Character: NSColor]), scale: Int) -> NSImage {
        let rows = art.0
        let colors = art.1
        let width = rows.first?.count ?? 0
        let height = rows.count
        let size = NSSize(width: width * scale, height: height * scale)
        let image = NSImage(size: size)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .none
        for (y, row) in rows.enumerated() {
            for (x, character) in row.enumerated() {
                guard let color = colors[character] else { continue }
                color.setFill()
                NSRect(
                    x: x * scale,
                    y: (height - 1 - y) * scale,
                    width: scale,
                    height: scale
                ).fill()
            }
        }
        image.unlockFocus()
        return image
    }
}

private let outline = NSColor(srgbRed: 0.08, green: 0.06, blue: 0.10, alpha: 1)
private let tire = NSColor(srgbRed: 0.07, green: 0.06, blue: 0.08, alpha: 1)
private let rim = NSColor(srgbRed: 0.72, green: 0.74, blue: 0.80, alpha: 1)
private let bumper = NSColor(srgbRed: 0.86, green: 0.88, blue: 0.92, alpha: 1)
private let chrome = NSColor(srgbRed: 0.55, green: 0.58, blue: 0.64, alpha: 1)

private func carColors(body: NSColor, highlight: NSColor, shade: NSColor, glass: NSColor, shine: NSColor, light: NSColor) -> [Character: NSColor] {
    [
        "O": outline,
        "B": body,
        "H": highlight,
        "D": shade,
        "W": glass,
        "G": shine,
        "L": light,
        "T": tire,
        "R": rim,
        "U": bumper,
        "C": chrome,
        "M": NSColor(srgbRed: 0.18, green: 0.18, blue: 0.22, alpha: 1)
    ]
}

/// Rear 3/4 view for the player car at the bottom of the road.
private func rearCarPixels(body: NSColor, highlight: NSColor, shade: NSColor, glass: NSColor, shine: NSColor, light: NSColor) -> ([String], [Character: NSColor]) {
    let rows = [
        ".......OOOOOO.......",
        "......OHHHHHHO......",
        ".....OHBBBBBBHO.....",
        "....OHBWWWWWWBHO....",
        "...OHBWWGGWWWWBHO...",
        "...OHBWWWWWWWWBHO...",
        "..OOHBBBBBBBBBBHOO..",
        "..OMHBBBBBBBBBBHMO..",
        "..OHBBBBBBBBBBBBHO..",
        ".OOHDBBBBBBBBBBDHOO.",
        ".OTDBBBBBBBBBBBBDTO.",
        ".OTRBBBBBBBBBBBBRTO.",
        ".OUBBBBBBBBBBBBBBUO.",
        ".OULBBBBBBBBBBBBLUO.",
        ".OCULUUUUUUUUUULUCO.",
        ".OT..UUUUUUUUUU..TO.",
        ".OR..............RO.",
        "..OO............OO.."
    ]
    return (rows, carColors(body: body, highlight: highlight, shade: shade, glass: glass, shine: shine, light: light))
}

/// Front 3/4 view for oncoming traffic.
private func frontCarPixels(body: NSColor, highlight: NSColor, shade: NSColor, glass: NSColor, shine: NSColor, light: NSColor) -> ([String], [Character: NSColor]) {
    let rows = [
        ".......OOOOOO.......",
        "......OHHHHHHO......",
        ".....OHBBBBBBHO.....",
        "....OHBWWWWWWBHO....",
        "...OHWWGGWWWWWWHO...",
        "...OHWWWWWWWWWWHO...",
        "..OOHBBBBBBBBBBHOO..",
        "..OMHBBHHHHHHBBHMO..",
        "..OHBBHHHHHHHHBBHO..",
        ".OOHDBBHHHHHHBBDHOO.",
        ".OTDBBBBBBBBBBBBDTO.",
        ".OTRBBBBBBBBBBBBRTO.",
        ".OUBBBBBBBBBBBBBBUO.",
        ".OULUUUUUUUUUUUULUO.",
        ".OCULCCCCCCCCCCLUCO.",
        ".OT..UUUUUUUUUU..TO.",
        ".OR..............RO.",
        "..OO............OO.."
    ]
    return (rows, carColors(body: body, highlight: highlight, shade: shade, glass: glass, shine: shine, light: light))
}

private func asphaltPixels() -> ([String], [Character: NSColor]) {
    let rows = [
        "abaaabbaaabaaabb",
        "aaabaaabaaabaaab",
        "baaabaaabaaabaaa",
        "aabaaabaaabaaaba",
        "aaabaaabaabaaaab",
        "baaabaaabaaabaaa",
        "aabaaabaaabaaaba",
        "aaabaabaaabaaaab",
        "baaabaaabaaabaaa",
        "aabaaabaaabaaaba",
        "aaabaaabaabaaaab",
        "baaabaaabaaabaaa",
        "aabaaabaaabaaaba",
        "aaabaaabaabaaaab",
        "baaabaaabaaabaaa",
        "aabaaabaaabaaaba"
    ]
    return (rows, [
        "a": NSColor(srgbRed: 0.17, green: 0.18, blue: 0.22, alpha: 1),
        "b": NSColor(srgbRed: 0.22, green: 0.23, blue: 0.28, alpha: 1)
    ])
}

private func stripePixels() -> ([String], [Character: NSColor]) {
    ([
        ".WW.",
        "WWWW",
        "WWWW",
        "WWWW",
        "WWWW",
        "WWWW",
        ".WW.",
        "...."
    ], [
        "W": NSColor(srgbRed: 0.96, green: 0.94, blue: 0.78, alpha: 1)
    ])
}

private func cactusPixels() -> ([String], [Character: NSColor]) {
    ([
        "...G...",
        "..GGG..",
        ".GG.GG.",
        "G.G.G.G",
        "..G.G..",
        "..GGG..",
        "...G...",
        "...D...",
        "...D..."
    ], [
        "G": NSColor(srgbRed: 0.25, green: 0.68, blue: 0.35, alpha: 1),
        "D": NSColor(srgbRed: 0.17, green: 0.48, blue: 0.25, alpha: 1)
    ])
}

private func rockPixels() -> ([String], [Character: NSColor]) {
    ([
        "..aaa.",
        ".aAAAa",
        "aAAAAA",
        ".aaaa."
    ], [
        "a": NSColor(srgbRed: 0.42, green: 0.40, blue: 0.44, alpha: 1),
        "A": NSColor(srgbRed: 0.54, green: 0.52, blue: 0.56, alpha: 1)
    ])
}

private func moonPixels() -> ([String], [Character: NSColor]) {
    ([
        "..www.",
        ".wWWww",
        "wWWWWW",
        "wWWwWW",
        ".wWWw.",
        "..ww.."
    ], [
        "w": NSColor(srgbRed: 0.90, green: 0.88, blue: 0.72, alpha: 1),
        "W": NSColor(srgbRed: 1, green: 0.96, blue: 0.82, alpha: 1)
    ])
}

private func starPixels() -> ([String], [Character: NSColor]) {
    ([
        ".Y.",
        "YYY",
        ".Y."
    ], [
        "Y": NSColor(srgbRed: 1, green: 0.96, blue: 0.66, alpha: 1)
    ])
}
