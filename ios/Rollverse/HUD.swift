//  HUD.swift
//  Rollverse — on-screen overlay (chips, heat bar, district banner, Skate-Jail
//  and intro cards). Added as a child of the camera so it stays fixed on screen.
//  Camera space: origin at screen centre, +y up.

import SpriteKit

final class HUD: SKNode {

    private let pad: CGFloat = 16
    private var size: CGSize = .zero

    // Chips
    private let scoreChip = ChipNode(key: "SCORE", valueColor: Palette.volt, mono: true)
    private let comboChip = ChipNode(key: "COMBO", valueColor: Palette.coral, mono: true)
    private let coinsChip = ChipNode(key: "COINS", valueColor: Palette.gold, mono: true)
    private let rideChip  = ChipNode(key: "RIDING", valueColor: Palette.cyan, mono: false, small: true)

    // S-K-A-T-E progress
    private let skateNode = SKNode()
    private var skateLabels: [SKLabelNode] = []

    // Heat
    private let heatChip = SKShapeNode()
    private let heatKey = Art0.label("HEAT", size: 9, color: SKColor(hex: 0xc9c1e6))
    private let heatBarBG = SKShapeNode(rectOf: CGSize(width: 96, height: 9), cornerRadius: 4.5)
    private let heatBarFill = SKShapeNode()

    // Banner
    private let bannerBG = SKShapeNode()
    private let bannerLabel = Art0.label("", size: 26, color: .white, font: "AvenirNext-Heavy")

    // Switch hint (top-right)
    private let switchHint = ChipNode(key: "SWITCH", valueColor: Palette.cyan, mono: false, small: true)

    // Jail overlay
    let jailNode = SKNode()
    private let jailCountdown = Art0.label("3", size: 52, color: Palette.gold, font: "Menlo-Bold")

    // Intro overlay
    let introNode = SKNode()

    // Mini-map
    private let miniMap = SKNode()
    private let mapDot = SKShapeNode(circleOfRadius: 4)
    private let mapW: CGFloat = 172
    private var mapH: CGFloat { mapW * World.height / World.width }
    private func mapPoint(_ wx: CGFloat, _ wy: CGFloat) -> CGPoint {
        CGPoint(x: -mapW / 2 + wx / World.width * mapW, y: mapH / 2 - wy / World.height * mapH)
    }

    override init() {
        super.init()
        zPosition = 100_000
        build()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func build() {
        addChild(scoreChip); addChild(comboChip); addChild(coinsChip); addChild(rideChip)
        comboChip.isHidden = true

        for ch in ["S", "K", "A", "T", "E"] {
            let l = Art0.label(ch, size: 15, color: SKColor(white: 1, alpha: 0.22), font: "AvenirNext-Heavy")
            l.horizontalAlignmentMode = .left
            skateLabels.append(l); skateNode.addChild(l)
        }
        addChild(skateNode)

        buildMiniMap()
        addChild(miniMap)

        heatBarBG.fillColor = SKColor(white: 1, alpha: 0.15); heatBarBG.strokeColor = .clear
        heatBarFill.fillColor = Palette.coral; heatBarFill.strokeColor = .clear
        heatChip.addChild(heatKey); heatChip.addChild(heatBarBG); heatChip.addChild(heatBarFill)
        addChild(heatChip)

        bannerBG.fillColor = SKColor(hex: 0x0f0d17, alpha: 0.67)
        bannerBG.strokeColor = SKColor(white: 1, alpha: 0.13); bannerBG.lineWidth = 1
        bannerBG.addChild(bannerLabel)
        bannerBG.alpha = 0
        addChild(bannerBG)

        switchHint.setValue("Ride (tap ⟳)")
        switchHint.isHidden = true
        addChild(switchHint)

        buildJail()
        buildIntro()
    }

    private func buildMiniMap() {
        let w = mapW, h = mapH
        let bg = SKShapeNode(rectOf: CGSize(width: w + 8, height: h + 8), cornerRadius: 8)
        bg.fillColor = SKColor(hex: 0x0f0d17, alpha: 0.8); bg.strokeColor = SKColor(white: 1, alpha: 0.15); bg.lineWidth = 1
        miniMap.addChild(bg)

        func district(_ x0: CGFloat, _ x1: CGFloat, _ col: SKColor) {
            let rx0 = -w / 2 + x0 / World.width * w
            let r = SKShapeNode(rect: CGRect(x: rx0, y: -h / 2, width: (x1 - x0) / World.width * w, height: h))
            r.fillColor = col.withAlphaComponent(0.85); r.strokeColor = SKColor(white: 0, alpha: 0.25); r.lineWidth = 1
            miniMap.addChild(r)
        }
        district(0, World.Road.x0, Palette.plazaFloor)
        district(World.Road.x0, World.Road.x1, Palette.roadFloor)
        district(World.Road.x1, World.width, Palette.bowlFloor)

        func mark(_ wx: CGFloat, _ wy: CGFloat, _ col: SKColor, _ r: CGFloat) {
            let d = SKShapeNode(circleOfRadius: r); d.fillColor = col; d.strokeColor = .clear
            d.position = mapPoint(wx, wy); miniMap.addChild(d)
        }
        for tn in World.tunnels { mark(tn.x + tn.w / 2, tn.y + tn.h / 2, Palette.cyan, 2.5) }
        mark(3000, 900, Palette.volt, 3)   // scooter pickup

        func mapLabel(_ text: String, _ wx: CGFloat) {
            let l = Art0.label(text, size: 8, color: SKColor(white: 1, alpha: 0.6))
            l.position = CGPoint(x: -w / 2 + wx / World.width * w, y: h / 2 - 7); miniMap.addChild(l)
        }
        mapLabel("PLAZA", World.Road.x0 / 2)
        mapLabel("RD", (World.Road.x0 + World.Road.x1) / 2)
        mapLabel("BOWL", (World.Road.x1 + World.width) / 2)

        mapDot.fillColor = Palette.coral; mapDot.strokeColor = .white; mapDot.lineWidth = 1
        mapDot.zPosition = 5
        miniMap.addChild(mapDot)
    }

    func setMapPlayer(_ wx: CGFloat, _ wy: CGFloat) { mapDot.position = mapPoint(wx, wy) }

    // MARK: layout

    func layout(_ s: CGSize) {
        size = s
        let left = -s.width / 2 + pad
        let top = s.height / 2 - pad

        scoreChip.position = CGPoint(x: left + scoreChip.halfWidth, y: top - 16)
        coinsChip.position = CGPoint(x: scoreChip.position.x + scoreChip.halfWidth + 8 + coinsChip.halfWidth, y: top - 16)
        comboChip.position = CGPoint(x: coinsChip.position.x + coinsChip.halfWidth + 8 + comboChip.halfWidth, y: top - 16)
        let afterCombo = comboChip.isHidden ? coinsChip.position.x + coinsChip.halfWidth : comboChip.position.x + comboChip.halfWidth
        rideChip.position = CGPoint(x: afterCombo + 8 + rideChip.halfWidth, y: top - 16)

        skateNode.position = CGPoint(x: left + 4, y: top - 44)
        for (i, l) in skateLabels.enumerated() { l.position = CGPoint(x: CGFloat(i) * 20, y: 0) }

        heatChip.position = CGPoint(x: rideChip.position.x + rideChip.halfWidth + 12 + 60, y: top - 16)
        heatKey.position = CGPoint(x: -60, y: 0)
        heatBarBG.position = CGPoint(x: 0, y: 0)
        layoutHeatFill()

        miniMap.position = CGPoint(x: 0, y: top - mapH / 2 - 6)
        bannerBG.position = CGPoint(x: 0, y: top - mapH - 44)

        switchHint.position = CGPoint(x: s.width / 2 - pad - switchHint.halfWidth, y: top - 16)

        layoutOverlays(s)
    }

    // MARK: dynamic setters

    func setScore(_ v: Int) { scoreChip.setValue("\(v)") }

    func setCoins(_ v: Int) { coinsChip.setValue("\(v)"); layout(size) }

    func setSkate(_ got: [Bool]) {
        for (i, l) in skateLabels.enumerated() where i < got.count {
            l.fontColor = got[i] ? Palette.volt : SKColor(white: 1, alpha: 0.22)
        }
    }

    func setCombo(_ v: Int) {
        if v > 0 {
            comboChip.isHidden = false
            comboChip.setValue("x\(v)")
        } else {
            comboChip.isHidden = true
        }
        layout(size)
    }

    func setRide(_ label: String) { rideChip.setValue(label); layout(size) }

    func setHeat(_ heat: CGFloat, max: CGFloat) {
        heatFrac = clampf(heat / max, 0, 1)
        layoutHeatFill()
        heatBarBG.glowWidth = heat >= max ? 3 : 0
        heatBarBG.strokeColor = heat >= max ? Palette.coral : .clear
    }

    private var heatFrac: CGFloat = 0
    private func layoutHeatFill() {
        let w = 96 * heatFrac
        heatBarFill.path = CGPath(roundedRect: CGRect(x: -48, y: -4.5, width: max(0.001, w), height: 9),
                                  cornerWidth: 4.5, cornerHeight: 4.5, transform: nil)
        heatBarFill.fillColor = heatFrac > 0.6 ? Palette.coral : Palette.gold
    }

    // The RIDE control button already signals switching, so keep this hint hidden
    // (it was overlapping the GEAR button).
    func showSwitchHint(_ show: Bool) { switchHint.isHidden = true }

    func showBanner(_ text: String) {
        bannerLabel.text = text
        let w = bannerLabel.frame.width + 44
        bannerBG.path = CGPath(roundedRect: CGRect(x: -w / 2, y: -24, width: w, height: 48),
                               cornerWidth: 14, cornerHeight: 14, transform: nil)
        bannerLabel.position = CGPoint(x: 0, y: 0)
        bannerBG.removeAllActions()
        bannerBG.run(.sequence([.fadeIn(withDuration: 0.4), .wait(forDuration: 1.4), .fadeOut(withDuration: 0.4)]))
    }

    // MARK: Jail

    private func buildJail() {
        jailNode.zPosition = 200
        jailNode.isHidden = true
        addChild(jailNode)
    }

    private let jailBG = SKShapeNode()
    private let jailBox = SKShapeNode()

    func showJail() { jailNode.isHidden = false }
    func hideJail() { jailNode.isHidden = true }
    func setJailCountdown(_ n: Int) { jailCountdown.text = "\(n)" }

    // MARK: Intro

    private let introBG = SKShapeNode()
    private let introCard = SKShapeNode()

    private func buildIntro() {
        introNode.zPosition = 300
        addChild(introNode)
    }

    // MARK: overlay layout (needs size)

    private func layoutOverlays(_ s: CGSize) {
        // Jail
        jailNode.removeAllChildren()
        jailBG.path = CGPath(rect: CGRect(x: -s.width / 2, y: -s.height / 2, width: s.width, height: s.height), transform: nil)
        jailBG.fillColor = SKColor(hex: 0x0b0913, alpha: 0.88); jailBG.strokeColor = .clear
        jailNode.addChild(jailBG)
        let box = SKShapeNode(rectOf: CGSize(width: 360, height: 220), cornerRadius: 20)
        box.fillColor = SKColor(hex: 0x191527); box.strokeColor = SKColor(hex: 0x4a3a6a); box.lineWidth = 1
        jailNode.addChild(box)
        let title = Art0.label("SKATE JAIL", size: 40, color: Palette.coral, font: "AvenirNext-Heavy"); title.position = CGPoint(x: 0, y: 70)
        let sub = Art0.label("Busted for skating into people!", size: 14, color: Palette.muted); sub.position = CGPoint(x: 0, y: 40)
        let bars = Art0.label("▯▮▯▮▯▮▯", size: 34, color: SKColor(hex: 0x6f6790)); bars.position = CGPoint(x: 0, y: 6)
        jailCountdown.position = CGPoint(x: 0, y: -48)
        let hint = Art0.label("Take it easy on the crowd out there…", size: 12, color: Palette.muted); hint.position = CGPoint(x: 0, y: -88)
        jailNode.addChild(title); jailNode.addChild(sub); jailNode.addChild(bars); jailNode.addChild(jailCountdown); jailNode.addChild(hint)

        // Intro
        introNode.removeAllChildren()
        let ibg = SKShapeNode(rect: CGRect(x: -s.width / 2, y: -s.height / 2, width: s.width, height: s.height))
        ibg.fillColor = SKColor(hex: 0x0b0913, alpha: 0.96); ibg.strokeColor = .clear
        introNode.addChild(ibg)
        let card = SKShapeNode(rectOf: CGSize(width: min(460, s.width - 40), height: 300), cornerRadius: 20)
        card.fillColor = SKColor(hex: 0x181426); card.strokeColor = SKColor(hex: 0x332a4d); card.lineWidth = 1
        introNode.addChild(card)
        let tag = Art0.label("ROLLVERSE · v3 · iOS", size: 12, color: Palette.cyan); tag.position = CGPoint(x: 0, y: 110)
        let introTitle = Art0.label("ROLLVERSE", size: 40, color: .white, font: "AvenirNext-Heavy"); introTitle.position = CGPoint(x: 0, y: 70)
        let l1 = Art0.label("Skate the Street Plaza, cross the road (mind the cars!),", size: 14, color: Palette.muted); l1.position = CGPoint(x: 0, y: 30)
        let l2 = Art0.label("and reach the Bowl Park — where a scooter is waiting.", size: 14, color: Palette.muted); l2.position = CGPoint(x: 0, y: 10)
        let l3 = Art0.label("Left thumb steers · JUMP hops people · TRICK spins in the air.", size: 13, color: SKColor(hex: 0x8a80ad)); l3.position = CGPoint(x: 0, y: -22)
        let l4 = Art0.label("Don't smash into people — or a guard hauls you to Skate Jail!", size: 13, color: SKColor(hex: 0xff9ec2)); l4.position = CGPoint(x: 0, y: -46)
        let btn = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 12)
        btn.fillColor = Palette.coral; btn.strokeColor = .clear; btn.position = CGPoint(x: 0, y: -95); btn.name = "startBtn"
        let btnL = Art0.label("Drop in ▶", size: 17, color: SKColor(hex: 0x1a0a06), font: "AvenirNext-Bold"); btnL.position = CGPoint(x: 0, y: -95)
        [tag, introTitle, l1, l2, l3, l4].forEach { introNode.addChild($0) }
        introNode.addChild(btn); introNode.addChild(btnL)
    }
}

// A rounded "chip" with a key label and a value label, matching the web HUD pills.
final class ChipNode: SKNode {
    private let bg = SKShapeNode()
    private let keyLabel: SKLabelNode
    private let valueLabel: SKLabelNode
    private(set) var halfWidth: CGFloat = 30

    init(key: String, valueColor: SKColor, mono: Bool, small: Bool = false) {
        keyLabel = Art0.label(key, size: 9, color: SKColor(hex: 0xc9c1e6))
        valueLabel = Art0.label("0", size: small ? 14 : 17, color: valueColor,
                                font: mono ? "Menlo-Bold" : "AvenirNext-Heavy")
        super.init()
        keyLabel.horizontalAlignmentMode = .left
        valueLabel.horizontalAlignmentMode = .left
        addChild(bg); addChild(keyLabel); addChild(valueLabel)
        relayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    func setValue(_ s: String) { valueLabel.text = s; relayout() }

    private func relayout() {
        let kw = keyLabel.frame.width
        let vw = valueLabel.frame.width
        let inner = kw + 7 + vw
        let w = inner + 24
        halfWidth = w / 2
        bg.path = CGPath(roundedRect: CGRect(x: -w / 2, y: -15, width: w, height: 30),
                         cornerWidth: 15, cornerHeight: 15, transform: nil)
        bg.fillColor = SKColor(hex: 0x0f0d17, alpha: 0.8)
        bg.strokeColor = SKColor(white: 1, alpha: 0.13); bg.lineWidth = 1
        keyLabel.position = CGPoint(x: -w / 2 + 12, y: 0)
        valueLabel.position = CGPoint(x: -w / 2 + 12 + kw + 7, y: 0)
    }
}

// Namespaced label helper for HUD (upright text, no world y-flip here).
enum Art0 {
    static func label(_ text: String, size: CGFloat, color: SKColor, font: String = "AvenirNext-Bold") -> SKLabelNode {
        let l = SKLabelNode(text: text)
        l.fontName = font; l.fontSize = size; l.fontColor = color
        l.verticalAlignmentMode = .center; l.horizontalAlignmentMode = .center
        return l
    }
}
