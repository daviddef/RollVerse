//  Ragdoll.swift
//  Rollverse — jointed physics ragdolls (SpriteKit's built-in 2D physics).
//
//  A person is 6 limb bodies (head, torso, two arms, two legs) linked by pin joints
//  with rotation limits. On a hit we fling the torso with a linear + angular impulse
//  and let the joints flail. The world runs top-down with ZERO gravity, so a knocked
//  figure tumbles in the hit direction and settles in place (a slapstick "splat"),
//  then freezes so it stops jittering. Skaters, pedestrians and the officer all reuse
//  this — only colours change. Kid-friendly: they get back up (see GameScene).
//
//  Ragdolls live in `ragLayer` (a non-flipped sibling of worldRoot) because SpriteKit
//  physics misbehaves under a negatively-scaled parent. World point (x, y) maps to
//  ragLayer point (x, -y).

import SpriteKit

enum RagdollStyle {
    case pedestrian(hue: CGFloat)
    case officer
    case skater(deck: SKColor)
}

final class Ragdoll {
    static let category: UInt32 = 0x1 << 1

    let root = SKNode()
    private var bodies: [SKPhysicsBody] = []
    private var torso: SKShapeNode!
    private var deck: SKShapeNode?          // skater's board flies off separately
    private let style: RagdollStyle
    private var frozen = false

    init(style: RagdollStyle) {
        self.style = style
        build()
    }

    // MARK: build limbs (local space, y-up, torso centred at origin)

    private func build() {
        let skin = SKColor(hex: 0xf0c9a0)
        let bodyColor: SKColor, headColor: SKColor, capColor: SKColor
        switch style {
        case .pedestrian(let hue): bodyColor = SKColor.hsl(hue, 0.45, 0.62); headColor = skin; capColor = .clear
        case .officer:             bodyColor = SKColor(hex: 0x2f3aa0);        headColor = skin; capColor = SKColor(hex: 0x1c1830)
        case .skater(let deck):    bodyColor = Palette.riderRed;              headColor = Palette.skinTone; capColor = deck
        }

        torso = limb(w: 13, h: 20, color: bodyColor, at: CGPoint(x: 0, y: 0), mass: 0.14)
        let head = limbCircle(r: 7, color: headColor, at: CGPoint(x: 0, y: 17), mass: 0.05)
        if capColor != .clear {
            let cap = Art.topArc(0, -1, 9, capColor); cap.zRotation = .pi   // sits on top of head
            cap.yScale = -1; head.addChild(cap)
        }
        let armL = limb(w: 5, h: 15, color: bodyColor, at: CGPoint(x: -11, y: 4), mass: 0.04)
        let armR = limb(w: 5, h: 15, color: bodyColor, at: CGPoint(x: 11, y: 4), mass: 0.04)
        let legL = limb(w: 6, h: 16, color: Palette.wall, at: CGPoint(x: -4, y: -17), mass: 0.05)
        let legR = limb(w: 6, h: 16, color: Palette.wall, at: CGPoint(x: 4, y: -17), mass: 0.05)

        pendingJoints = [
            (head, torso, CGPoint(x: 0, y: 11), 0.8),
            (armL, torso, CGPoint(x: -7, y: 9), 1.5),
            (armR, torso, CGPoint(x: 7, y: 9), 1.5),
            (legL, torso, CGPoint(x: -4, y: -9), 1.2),
            (legR, torso, CGPoint(x: 4, y: -9), 1.2),
        ]

        if case .skater(let deckColor) = style {
            // the board detaches and tumbles on its own (no joint)
            let d = SKShapeNode(path: Art.roundRectPath(-16, -5, 32, 10, 5))
            d.fillColor = deckColor; d.strokeColor = .clear
            d.position = CGPoint(x: 0, y: -26)
            let b = SKPhysicsBody(rectangleOf: CGSize(width: 32, height: 10))
            b.categoryBitMask = Ragdoll.category; b.collisionBitMask = 0; b.contactTestBitMask = 0
            b.linearDamping = 2.5; b.angularDamping = 2.5
            d.physicsBody = b; bodies.append(b)
            root.addChild(d); deck = d
        }
    }

    private typealias PendingJoint = (SKShapeNode, SKShapeNode, CGPoint, CGFloat)
    private var pendingJoints: [PendingJoint] = []

    private func limb(w: CGFloat, h: CGFloat, color: SKColor, at pos: CGPoint, mass: CGFloat) -> SKShapeNode {
        let n = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: min(w, h) / 2)
        n.fillColor = color; n.strokeColor = .clear; n.position = pos
        let b = SKPhysicsBody(rectangleOf: CGSize(width: w, height: h))
        configure(b, mass: mass)
        n.physicsBody = b; bodies.append(b); root.addChild(n)
        return n
    }
    private func limbCircle(r: CGFloat, color: SKColor, at pos: CGPoint, mass: CGFloat) -> SKShapeNode {
        let n = SKShapeNode(circleOfRadius: r)
        n.fillColor = color; n.strokeColor = .clear; n.position = pos
        let b = SKPhysicsBody(circleOfRadius: r)
        configure(b, mass: mass)
        n.physicsBody = b; bodies.append(b); root.addChild(n)
        return n
    }
    private func configure(_ b: SKPhysicsBody, mass: CGFloat) {
        b.categoryBitMask = Ragdoll.category
        b.collisionBitMask = 0            // limbs pass through each other (no explosions)
        b.contactTestBitMask = 0
        b.linearDamping = 4.0; b.angularDamping = 4.0
        b.mass = mass
    }

    // MARK: attach + activate (called once root is in the scene tree)

    func wireJoints(in world: SKPhysicsWorld) {
        guard let scene = root.scene else { return }
        for (a, b, localAnchor, span) in pendingJoints {
            let anchor = root.convert(localAnchor, to: scene)
            let j = SKPhysicsJointPin.joint(withBodyA: a.physicsBody!, bodyB: b.physicsBody!, anchor: anchor)
            j.shouldEnableLimits = true
            j.lowerAngleLimit = -span; j.upperAngleLimit = span
            j.frictionTorque = 0.02
            world.add(j)
        }
        pendingJoints.removeAll()
    }

    /// Fling the figure. `dir` is in ragLayer space (y-up); `power` scales the impulse.
    func activate(dir: CGVector, power: CGFloat, spin: CGFloat, flatten: Bool = false) {
        let d = max(hypot2(dir.dx, dir.dy), 0.001)
        let imp = CGVector(dx: dir.dx / d * power, dy: dir.dy / d * power)
        torso.physicsBody?.applyImpulse(imp)
        torso.physicsBody?.applyAngularImpulse(spin)
        for b in bodies where b !== torso.physicsBody {
            b.applyImpulse(CGVector(dx: imp.dx * 0.5, dy: imp.dy * 0.5))
        }
        if let d = deck {
            d.physicsBody?.applyImpulse(CGVector(dx: imp.dx * 1.4, dy: imp.dy * 1.4 + 6))
            d.physicsBody?.applyAngularImpulse(0.05)
        }
        if flatten { root.run(.scaleY(to: 0.55, duration: 0.18)) }   // "steamrollered" squash
    }

    /// Stop simulating so the pile stops twitching.
    func freeze() {
        guard !frozen else { return }
        frozen = true
        for b in bodies { b.isResting = true; b.velocity = .zero; b.angularVelocity = 0; b.isDynamic = false }
    }

    func fadeAndRemove(after delay: TimeInterval) {
        root.run(.sequence([.wait(forDuration: delay),
                            .fadeOut(withDuration: 0.35),
                            .removeFromParent()]))
    }
}
