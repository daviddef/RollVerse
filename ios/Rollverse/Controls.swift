//  Controls.swift
//  Rollverse — touch controls. A floating left-thumb joystick (steer any of 8+
//  directions) and right-hand JUMP / TRICK / RIDE buttons. Lives on the camera so
//  it stays fixed on screen. Buttons edge-trigger, matching the web build's
//  jumpBuf / trickBuf / switchBuf one-shot flags.

import SpriteKit

final class Controls: SKNode {

    // Output read by GameScene each frame.
    private(set) var stickVec = CGVector(dx: 0, dy: 0)   // magnitude <= 1, +y = up

    var onJump: () -> Void = {}
    var onTrick: () -> Void = {}
    var onSwitch: () -> Void = {}
    var onGarage: () -> Void = {}
    var onTricks: () -> Void = {}

    private let maxTravel: CGFloat = 55
    private var size: CGSize = .zero

    // Joystick
    private let stickBase = SKShapeNode(circleOfRadius: 63)
    private let stickNub  = SKShapeNode(circleOfRadius: 27)
    private var stickTouch: UITouch?
    private var stickOrigin = CGPoint.zero
    private var homeBase = CGPoint.zero

    // Buttons
    private let jumpBtn = ButtonNode(title: "JUMP", tint: Palette.coral, radius: 42)
    private let trickBtn = ButtonNode(title: "TRICK", tint: Palette.cyan, radius: 42)
    private let switchBtn = ButtonNode(title: "RIDE", tint: Palette.volt, radius: 34)
    private let garageBtn = ButtonNode(title: "GEAR", tint: Palette.violet, radius: 28)
    private let tricksBtn = ButtonNode(title: "?", tint: Palette.cyan, radius: 24)

    override init() {
        super.init()
        zPosition = 90_000
        isUserInteractionEnabled = false   // GameScene forwards touches to us

        stickBase.fillColor = SKColor(white: 1, alpha: 0.07)
        stickBase.strokeColor = SKColor(white: 1, alpha: 0.17); stickBase.lineWidth = 1
        stickNub.fillColor = SKColor(white: 1, alpha: 0.19)
        stickNub.strokeColor = SKColor(white: 1, alpha: 0.33); stickNub.lineWidth = 1
        stickBase.addChild(stickNub)
        stickBase.alpha = 0.5
        addChild(stickBase)

        addChild(jumpBtn); addChild(trickBtn)
        switchBtn.isHidden = true
        addChild(switchBtn)
        addChild(garageBtn)
        addChild(tricksBtn)
    }
    required init?(coder: NSCoder) { fatalError() }

    func layout(_ s: CGSize) {
        size = s
        homeBase = CGPoint(x: -s.width / 2 + 110, y: -s.height / 2 + 110)
        if stickTouch == nil { stickBase.position = homeBase; stickNub.position = .zero }
        jumpBtn.position = CGPoint(x: s.width / 2 - 66, y: -s.height / 2 + 70)
        trickBtn.position = CGPoint(x: s.width / 2 - 66, y: -s.height / 2 + 168)
        switchBtn.position = CGPoint(x: s.width / 2 - 158, y: -s.height / 2 + 66)
        garageBtn.position = CGPoint(x: s.width / 2 - 46, y: s.height / 2 - 46)
        tricksBtn.position = CGPoint(x: s.width / 2 - 112, y: s.height / 2 - 46)
    }

    func showSwitch(_ show: Bool) { switchBtn.isHidden = !show }

    // MARK: touch routing (called by GameScene). `loc` is in this node's space.

    func touchDown(_ touch: UITouch, at loc: CGPoint) {
        // Right side = buttons; left side = (floating) joystick.
        if loc.x > 0 {
            if tricksBtn.hit(loc) { tricksBtn.flash(); onTricks(); return }
            if garageBtn.hit(loc) { garageBtn.flash(); onGarage(); return }
            if !switchBtn.isHidden, switchBtn.hit(loc) { switchBtn.flash(); onSwitch(); return }
            if jumpBtn.hit(loc) { jumpBtn.flash(); onJump(); return }
            if trickBtn.hit(loc) { trickBtn.flash(); onTrick(); return }
            return
        }
        guard stickTouch == nil else { return }
        stickTouch = touch
        stickOrigin = loc
        stickBase.position = loc
        stickNub.position = .zero
        stickBase.alpha = 0.9
    }

    func touchMoved(_ touch: UITouch, at loc: CGPoint) {
        guard touch == stickTouch else { return }
        var dx = loc.x - stickOrigin.x
        var dy = loc.y - stickOrigin.y
        let d = hypot2(dx, dy)
        let clamped = min(d, maxTravel)
        if d > 0 { dx = dx / d * clamped; dy = dy / d * clamped }
        stickNub.position = CGPoint(x: dx, y: dy)
        stickVec = CGVector(dx: dx / maxTravel, dy: dy / maxTravel)
    }

    func touchUp(_ touch: UITouch) {
        guard touch == stickTouch else { return }
        stickTouch = nil
        stickVec = .zero
        stickNub.position = .zero
        stickBase.position = homeBase
        stickBase.alpha = 0.5
    }
}

final class ButtonNode: SKNode {
    private let ring: SKShapeNode
    private let radius: CGFloat

    init(title: String, tint: SKColor, radius: CGFloat) {
        self.radius = radius
        ring = SKShapeNode(circleOfRadius: radius)
        super.init()
        ring.fillColor = tint.withAlphaComponent(0.19)
        ring.strokeColor = tint; ring.lineWidth = 2
        addChild(ring)
        let l = Art0.label(title, size: radius > 40 ? 13 : 11, color: .white, font: "AvenirNext-Bold")
        addChild(l)
    }
    required init?(coder: NSCoder) { fatalError() }

    func hit(_ loc: CGPoint) -> Bool { hypot2(loc.x - position.x, loc.y - position.y) <= radius + 6 }

    func flash() {
        ring.removeAllActions()
        ring.run(.sequence([.scale(to: 0.86, duration: 0.05), .scale(to: 1.0, duration: 0.12)]))
    }
}
