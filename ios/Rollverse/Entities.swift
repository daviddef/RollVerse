//  Entities.swift
//  Rollverse — vector art builders, ported from the <canvas> draw calls in
//  rollverse-v2.html. The world container (worldRoot) is drawn with yScale = -1,
//  so every coordinate here is authored in the SAME y-DOWN space as the web
//  prototype — the shapes are near-verbatim transcriptions of the canvas code.
//  (SKLabelNodes are counter-flipped so text stays upright.)

import SpriteKit

// MARK: - Tiny shape helpers

enum Art {
    static func roundRectPath(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> CGPath {
        CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h),
               cornerWidth: min(r, w / 2), cornerHeight: min(r, h / 2), transform: nil)
    }

    static func fillRoundRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat, _ color: SKColor) -> SKShapeNode {
        let n = SKShapeNode(path: roundRectPath(x, y, w, h, r))
        n.fillColor = color; n.strokeColor = .clear; n.isAntialiased = true
        return n
    }

    static func fillRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: SKColor) -> SKShapeNode {
        let n = SKShapeNode(rect: CGRect(x: x, y: y, width: w, height: h))
        n.fillColor = color; n.strokeColor = .clear
        return n
    }

    static func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: SKColor) -> SKShapeNode {
        let n = SKShapeNode(circleOfRadius: r)
        n.position = CGPoint(x: cx, y: cy)
        n.fillColor = color; n.strokeColor = .clear
        return n
    }

    static func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ w: CGFloat, _ color: SKColor) -> SKShapeNode {
        let p = CGMutablePath(); p.move(to: CGPoint(x: x1, y: y1)); p.addLine(to: CGPoint(x: x2, y: y2))
        let n = SKShapeNode(path: p)
        n.strokeColor = color; n.lineWidth = w; n.lineCap = .round
        return n
    }

    /// A filled half-disc cap (used for hair/caps), like ctx.arc(cx,cy,r,PI,0) + close.
    static func topArc(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: SKColor) -> SKShapeNode {
        let p = CGMutablePath()
        // In canvas y-down, arc(cx,cy,r, PI, 0) sweeps the upper half.
        p.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .pi, endAngle: 0, clockwise: false)
        p.closeSubpath()
        let n = SKShapeNode(path: p); n.fillColor = color; n.strokeColor = .clear
        return n
    }

    static func label(_ text: String, size: CGFloat, color: SKColor,
                      font: String = "AvenirNext-Heavy") -> SKLabelNode {
        let l = SKLabelNode(text: text)
        l.fontName = font; l.fontSize = size; l.fontColor = color
        l.verticalAlignmentMode = .center; l.horizontalAlignmentMode = .center
        l.yScale = -1                       // counter-flip inside the y-flipped worldRoot
        return l
    }

    /// A small name tag placed above a trick object (so you learn what each one is).
    static func tag(_ text: String, _ x: CGFloat, _ y: CGFloat) -> SKLabelNode {
        let l = label(text, size: 15, color: SKColor(hex: 0xdcd6f0, alpha: 0.72), font: "AvenirNext-Bold")
        l.position = CGPoint(x: x, y: y)
        l.zPosition = 40
        return l
    }
}

// MARK: - Static world geometry

enum Entities {

    static func buildGround() -> SKNode {
        let root = SKNode()
        root.zPosition = -1000

        // District & road floors
        root.addChild(Art.fillRect(0, 0, World.Road.x0, World.height, Palette.plazaFloor))
        root.addChild(Art.fillRect(World.Road.x1, 0, World.Sea.beachX0 - World.Road.x1, World.height, Palette.bowlFloor))
        root.addChild(Art.fillRect(World.Road.x0, 0, World.Road.x1 - World.Road.x0, World.height, Palette.roadFloor))
        // Beach sand
        root.addChild(Art.fillRect(World.Sea.beachX0, 0, World.Sea.oceanX0 - World.Sea.beachX0, World.height, SKColor(hex: 0xe6cf9c)))
        root.addChild(Art.fillRect(World.Sea.beachX0, 0, 12, World.height, SKColor(hex: 0xcbb277)))   // curb-ish edge
        // Curbs
        root.addChild(Art.fillRect(World.Road.x0 - 10, 0, 10, World.height, Palette.curb))
        root.addChild(Art.fillRect(World.Road.x1, 0, 10, World.height, Palette.curb))

        // Lane dashes down the middle of the road
        let mid = (World.Road.x0 + World.Road.x1) / 2
        let dashP = CGMutablePath(); dashP.move(to: CGPoint(x: mid, y: 0)); dashP.addLine(to: CGPoint(x: mid, y: World.height))
        let dash = SKShapeNode(path: dashP.copy(dashingWithPhase: 0, lengths: [26, 26]))
        dash.strokeColor = SKColor(hex: 0xffd35e, alpha: 0.53); dash.lineWidth = 4
        root.addChild(dash)

        // Crosswalk — lots of zebra stripes across the road
        let cwCount = 15, cwSpan = (World.Road.x1 - World.Road.x0 - 24) / CGFloat(cwCount)
        for cw in 0..<cwCount {
            root.addChild(Art.fillRect(World.Road.x0 + 14 + CGFloat(cw) * cwSpan,
                                       World.crossY - 62, cwSpan * 0.55, 124,
                                       SKColor(hex: 0xe8e4f0, alpha: 0.72)))
        }

        // Tile grid in the districts
        let grid = CGMutablePath()
        var x: CGFloat = 0
        while x <= World.Sea.beachX0 {
            if x < World.Road.x0 - 10 || x > World.Road.x1 + 10 {
                grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: World.height))
            }
            x += 120
        }
        var y: CGFloat = 0
        while y <= World.height {
            grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: World.Road.x0, y: y))
            grid.move(to: CGPoint(x: World.Road.x1, y: y)); grid.addLine(to: CGPoint(x: World.Sea.beachX0, y: y))
            y += 120
        }
        let gridNode = SKShapeNode(path: grid)
        gridNode.strokeColor = SKColor(white: 0, alpha: 0.08); gridNode.lineWidth = 2
        root.addChild(gridNode)

        // Outer wall
        let wall = SKShapeNode(rect: CGRect(x: 8, y: 8, width: World.width - 16, height: World.height - 16))
        wall.strokeColor = Palette.wall; wall.lineWidth = 16; wall.fillColor = .clear
        root.addChild(wall)

        // Big painted district labels
        let plaza = Art.label("PLAZA", size: 120, color: SKColor(white: 1, alpha: 0.06)); plaza.position = CGPoint(x: 650, y: 300)
        let bowl = Art.label("BOWL", size: 120, color: SKColor(white: 1, alpha: 0.06)); bowl.position = CGPoint(x: 2900, y: 300)
        let beach = Art.label("BEACH", size: 100, color: SKColor(hex: 0xffffff, alpha: 0.10)); beach.position = CGPoint(x: 3950, y: 300)
        root.addChild(plaza); root.addChild(bowl); root.addChild(beach)

        return root
    }

    /// The sea: deep water, drifting wave crests, and a foam line at the shore.
    static func buildOcean() -> SKNode {
        let root = SKNode()
        root.zPosition = -960
        let x0 = World.Sea.oceanX0, w = World.width - x0, h = World.height
        // water bands (lighter near the shore -> deeper out to sea)
        let bands: [UInt32] = [0x2f89b0, 0x2877a0, 0x216690, 0x1b5680]
        let bw = w / CGFloat(bands.count)
        for (i, c) in bands.enumerated() {
            root.addChild(Art.fillRect(x0 + CGFloat(i) * bw, 0, bw + 1, h, SKColor(hex: c)))
        }
        // shoreline foam
        let foam = Art.fillRect(x0 - 6, 0, 20, h, SKColor(hex: 0xeaf6ff, alpha: 0.7))
        foam.run(.repeatForever(.sequence([.fadeAlpha(to: 0.35, duration: 0.9), .fadeAlpha(to: 0.8, duration: 0.9)])))
        root.addChild(foam)
        // drifting wave crests
        for i in 0..<26 {
            let wy = CGFloat((i * 137) % Int(h))
            let wx = x0 + 30 + CGFloat((i * 311) % Int(w - 60))
            let crest = Art.fillRoundRect(-26, -2, 52, 4, 2, SKColor(white: 1, alpha: 0.28))
            crest.position = CGPoint(x: wx, y: wy)
            let dur = 3.0 + Double(i % 5) * 0.6
            crest.run(.repeatForever(.sequence([
                .group([.moveBy(x: -34, y: 0, duration: dur), .fadeAlpha(to: 0.05, duration: dur)]),
                .group([.moveBy(x: 34, y: 0, duration: 0), .fadeAlpha(to: 0.28, duration: 0.01)]),
            ])))
            root.addChild(crest)
        }
        let sea = Art.label("SEA", size: 110, color: SKColor(hex: 0xffffff, alpha: 0.08)); sea.position = CGPoint(x: 4750, y: 300)
        root.addChild(sea)
        return root
    }

    /// A little boat drifting on the sea.
    static func buildBoat(_ b: Boat) -> SKNode {
        let root = SKNode()
        root.addChild({ let s = SKShapeNode(ellipseOf: CGSize(width: 60, height: 20))
            s.fillColor = SKColor(white: 0, alpha: 0.18); s.strokeColor = .clear; s.position = CGPoint(x: 0, y: 10); return s }())
        // hull
        let hull = CGMutablePath()
        hull.move(to: CGPoint(x: -34, y: -6)); hull.addLine(to: CGPoint(x: 34, y: -6))
        hull.addLine(to: CGPoint(x: 24, y: 14)); hull.addLine(to: CGPoint(x: -24, y: 14)); hull.closeSubpath()
        let hn = SKShapeNode(path: hull); hn.fillColor = b.col; hn.strokeColor = SKColor(white: 0, alpha: 0.2); hn.lineWidth = 2
        root.addChild(hn)
        // cabin + mast
        root.addChild(Art.fillRoundRect(-12, -20, 24, 16, 4, SKColor(hex: 0xeaf6ff)))
        root.addChild(Art.line(0, -20, 0, -44, 3, SKColor(hex: 0x8a7f6a)))
        let sail = CGMutablePath(); sail.move(to: CGPoint(x: 2, y: -44)); sail.addLine(to: CGPoint(x: 22, y: -14)); sail.addLine(to: CGPoint(x: 2, y: -14)); sail.closeSubpath()
        let sn = SKShapeNode(path: sail); sn.fillColor = SKColor(hex: 0xffce4a); sn.strokeColor = .clear
        root.addChild(sn)
        // gentle bob
        root.run(.repeatForever(.sequence([.moveBy(x: 0, y: -3, duration: 1.1), .moveBy(x: 0, y: 3, duration: 1.1)])))
        return root
    }

    static func buildBikePickup() -> SKNode {
        let root = SKNode()
        root.addChild({ let s = SKShapeNode(ellipseOf: CGSize(width: 40, height: 16))
            s.fillColor = SKColor(white: 0, alpha: 0.28); s.strokeColor = .clear; return s }())
        let icon = SKNode(); icon.position = CGPoint(x: 0, y: -20)
        let d = SKColor(hex: 0xd23b3b)
        icon.addChild(Art.circle(-12, 8, 8, SKColor(hex: 0x2a2436))); icon.addChild(Art.circle(-12, 8, 3, .white))
        icon.addChild(Art.circle(12, 8, 8, SKColor(hex: 0x2a2436))); icon.addChild(Art.circle(12, 8, 3, .white))
        icon.addChild(Art.line(-12, 8, 2, 2, 3, d)); icon.addChild(Art.line(2, 2, 12, 8, 3, d))
        icon.addChild(Art.line(2, 2, 0, -8, 3, d)); icon.addChild(Art.line(10, 8, 10, -4, 3, d))
        icon.addChild(Art.line(5, -4, 15, -4, 3, d))
        root.addChild(icon)
        let tag = Art.label("▲ bike", size: 13, color: Palette.volt); tag.position = CGPoint(x: 0, y: -42)
        root.addChild(tag)
        icon.run(.repeatForever(.sequence([.moveBy(x: 0, y: -6, duration: 0.5), .moveBy(x: 0, y: 6, duration: 0.5)])))
        return root
    }

    static func buildZone(_ z: World.Zone) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: z.x, y: z.y)
        root.zPosition = -900

        let fill = SKShapeNode(circleOfRadius: z.r)
        fill.fillColor = SKColor(hex: 0x37d6e6, alpha: 0.10); fill.strokeColor = .clear
        root.addChild(fill)

        let ringPath = CGPath(ellipseIn: CGRect(x: -z.r, y: -z.r, width: z.r * 2, height: z.r * 2), transform: nil)
        let ring = SKShapeNode(path: ringPath.copy(dashingWithPhase: 0, lengths: [10, 10]))
        ring.strokeColor = SKColor(hex: 0x37d6e6, alpha: 0.47); ring.lineWidth = 3; ring.fillColor = .clear
        root.addChild(ring)

        let tag = Art.label("TRICK ZONE x\(Int(z.mult))", size: 14, color: SKColor(hex: 0xdffbff))
        tag.position = CGPoint(x: 0, y: -z.r + 20)
        root.addChild(tag)
        return root
    }

    /// A proper ramp — a kicker (or quarter pipe): footprint with an inclined face
    /// (fake-shaded darker at the base, lighter toward the lip) and a bright coping.
    /// Local +x is the launch direction (root is rotated by `dir`).
    static func buildRamp(_ r: World.Ramp) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: r.x, y: r.y)
        root.zRotation = r.dir
        root.zPosition = -500
        let w = r.w, h = r.h

        // footprint shadow
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2 + 6, w, h, 12, SKColor(white: 0, alpha: 0.22)))
        // ramp deck base
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, h, 12, SKColor(hex: 0x322c46)))
        // incline bands (dark at the base -> light toward the lip)
        let bandColors: [UInt32] = [0x3c355a, 0x4d4670, 0x655d8c, 0x8079a6]
        let bw = w / CGFloat(bandColors.count + 1)
        for (i, c) in bandColors.enumerated() {
            let x = -w / 2 + bw * CGFloat(i + 1)
            root.addChild(Art.fillRoundRect(x, -h / 2 + 6, bw + 2, h - 12, 4, SKColor(hex: c)))
        }
        // bright coping / lip at the launch edge
        if r.kind == .quarter {
            // curved coping
            let p = CGMutablePath()
            p.addArc(center: CGPoint(x: w / 2 - 14, y: 0), radius: h / 2,
                     startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: false)
            let arc = SKShapeNode(path: p); arc.strokeColor = Palette.gold; arc.lineWidth = 7; arc.fillColor = .clear; arc.lineCap = .round
            root.addChild(arc)
        }
        root.addChild(Art.fillRoundRect(w / 2 - 10, -h / 2, 8, h, 4, Palette.gold))
        // side rails
        root.addChild(Art.fillRect(-w / 2, -h / 2, w, 3, SKColor(white: 1, alpha: 0.10)))
        root.addChild(Art.fillRect(-w / 2, h / 2 - 3, w, 3, SKColor(white: 0, alpha: 0.18)))
        return root
    }

    /// An accelerator pad — the chevron speed strip. Local +x is the boost direction.
    static func buildBooster(_ b: World.Booster) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: b.x, y: b.y)
        root.zRotation = b.dir
        root.zPosition = -450
        let len = b.len

        let pad = Art.fillRoundRect(-len / 2, -26, len, 52, 16, SKColor(hex: 0xc6ff42, alpha: 0.14))
        let ring = SKShapeNode(path: Art.roundRectPath(-len / 2, -26, len, 52, 16))
        ring.strokeColor = SKColor(hex: 0xc6ff42, alpha: 0.55); ring.lineWidth = 2; ring.fillColor = .clear
        root.addChild(pad); root.addChild(ring)

        let chevrons = SKNode()
        for i in 0..<3 {
            let x = -len / 2 + 34 + CGFloat(i) * 38
            let p = CGMutablePath()
            p.move(to: CGPoint(x: x - 9, y: -15)); p.addLine(to: CGPoint(x: x + 9, y: 0)); p.addLine(to: CGPoint(x: x - 9, y: 15))
            let n = SKShapeNode(path: p); n.strokeColor = Palette.volt; n.lineWidth = 6; n.lineCap = .round; n.lineJoin = .round; n.fillColor = .clear
            chevrons.addChild(n)
        }
        root.addChild(chevrons)
        chevrons.run(.repeatForever(.sequence([.fadeAlpha(to: 0.45, duration: 0.5),
                                               .fadeAlpha(to: 1.0, duration: 0.5)])))
        return root
    }

    /// A real half pipe (top-down): a flat trough in the middle with a curved
    /// transition bank rising to a coping lip at each end (top & bottom in world-y).
    static func buildHalfPipe(_ hp: World.HalfPipe) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: hp.x + hp.w / 2, y: hp.y + hp.h / 2)
        root.zPosition = -470
        let w = hp.w, h = hp.h
        // flat platform decks on top of each wall (where you stand to drop in)
        root.addChild(Art.fillRoundRect(-w / 2 - 6, -h / 2 - 34, w + 12, 34, 8, SKColor(hex: 0x4a4368)))
        root.addChild(Art.fillRoundRect(-w / 2 - 6, h / 2,      w + 12, 34, 8, SKColor(hex: 0x4a4368)))
        root.addChild(Art.fillRoundRect(-w / 2 - 6, -h / 2 - 8, w + 12, 5, 2, SKColor(white: 1, alpha: 0.12)))
        root.addChild(Art.fillRoundRect(-w / 2 - 6, h / 2 + 3,  w + 12, 5, 2, SKColor(white: 1, alpha: 0.12)))

        root.addChild(Art.fillRoundRect(-w / 2, -h / 2 + 8, w, h, 22, SKColor(white: 0, alpha: 0.22)))   // shadow
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, h, 22, SKColor(hex: 0x2b2640)))               // structure
        // flat bottom of the pipe
        root.addChild(Art.fillRoundRect(-w / 2 + 10, -h * 0.13, w - 20, h * 0.26, 10, SKColor(hex: 0x5f5880)))
        // curved transition banks: bands dark (flat) -> light (lip), top & bottom
        let bank: [UInt32] = [0x393354, 0x413a5f, 0x4d4670, 0x5b5482, 0x6e6799, 0x847dae, 0x9c95c4]
        let bandH = (h * 0.37) / CGFloat(bank.count)
        for (i, c) in bank.enumerated() {
            let inset = 12 - CGFloat(i) * 1.4
            let yTop = -h / 2 + 8 + CGFloat(bank.count - 1 - i) * bandH
            let yBot = h / 2 - 8 - bandH - CGFloat(bank.count - 1 - i) * bandH
            root.addChild(Art.fillRoundRect(-w / 2 + inset, yTop, w - inset * 2, bandH + 1, 4, SKColor(hex: c)))
            root.addChild(Art.fillRoundRect(-w / 2 + inset, yBot, w - inset * 2, bandH + 1, 4, SKColor(hex: c)))
        }
        // metal coping pipes on each lip + dark side walls
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2 - 3, w, 7, 3, SKColor(hex: 0xd7d0e6)))
        root.addChild(Art.fillRoundRect(-w / 2, h / 2 - 4,  w, 7, 3, SKColor(hex: 0xd7d0e6)))
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, 7, h, 3, SKColor(hex: 0x241f36)))
        root.addChild(Art.fillRoundRect(w / 2 - 7, -h / 2, 7, h, 3, SKColor(hex: 0x241f36)))
        return root
    }

    /// A small mellow bank — rises toward -y with a shaded slope + coping. For
    /// learning kick turns and basic transitions.
    static func buildBank(_ bk: World.Bank) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: bk.x + bk.w / 2, y: bk.y + bk.h / 2)
        root.zPosition = -455
        let w = bk.w, h = bk.h
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2 + 6, w, h, 14, SKColor(white: 0, alpha: 0.2)))   // shadow
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, h, 14, SKColor(hex: 0x33304a)))              // base
        // slope bands: dark at the base (bottom) -> light toward the top (coping)
        let band: [UInt32] = [0x3b3757, 0x494470, 0x5a5488, 0x6f68a0]
        let bh = (h - 10) / CGFloat(band.count)
        for (i, c) in band.enumerated() {
            let y = h / 2 - 5 - CGFloat(i + 1) * bh
            root.addChild(Art.fillRoundRect(-w / 2 + 6, y, w - 12, bh + 1, 4, SKColor(hex: c)))
        }
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, 5, 2, SKColor(hex: 0xd7d0e6)))                // coping
        return root
    }

    /// A flat practice pad: painted flat ground + a carve ring + a label.
    static func buildPracticePad(_ r: CGRect) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: r.midX, y: r.midY)
        root.zPosition = -485
        let w = r.width, h = r.height
        let pad = Art.fillRoundRect(-w / 2, -h / 2, w, h, 20, SKColor(hex: 0xc6ff42, alpha: 0.10))
        root.addChild(pad)
        let border = SKShapeNode(path: Art.roundRectPath(-w / 2, -h / 2, w, h, 20).copy(dashingWithPhase: 0, lengths: [14, 10]))
        border.strokeColor = SKColor(hex: 0xc6ff42, alpha: 0.5); border.lineWidth = 3; border.fillColor = .clear
        root.addChild(border)
        let ring = SKShapeNode(path: CGPath(ellipseIn: CGRect(x: -50, y: -50, width: 100, height: 100), transform: nil)
            .copy(dashingWithPhase: 0, lengths: [10, 10]))
        ring.strokeColor = SKColor(white: 1, alpha: 0.3); ring.lineWidth = 2; ring.fillColor = .clear
        root.addChild(ring)
        return root
    }

    static func buildCone() -> SKNode {
        let root = SKNode()
        root.addChild({ let s = SKShapeNode(ellipseOf: CGSize(width: 16, height: 7))
            s.fillColor = SKColor(white: 0, alpha: 0.28); s.strokeColor = .clear; return s }())
        let tri = CGMutablePath(); tri.move(to: CGPoint(x: -8, y: 0)); tri.addLine(to: CGPoint(x: 8, y: 0))
        tri.addLine(to: CGPoint(x: 2, y: -26)); tri.addLine(to: CGPoint(x: -2, y: -26)); tri.closeSubpath()
        let n = SKShapeNode(path: tri); n.fillColor = SKColor(hex: 0xff7a33); n.strokeColor = .clear
        root.addChild(n)
        root.addChild(Art.fillRect(-4, -17, 8, 4, SKColor(white: 1, alpha: 0.7)))   // reflective band
        return root
    }

    static func buildPuddle() -> SKShapeNode {
        let p = SKShapeNode(ellipseOf: CGSize(width: 70, height: 34))
        p.fillColor = SKColor(hex: 0x5aa0c8, alpha: 0.45); p.strokeColor = SKColor(hex: 0x9fd0e6, alpha: 0.4); p.lineWidth = 2
        p.zPosition = -300; p.alpha = 0        // fades in when it rains
        return p
    }

    /// A drop-in platform: a raised deck with a coping lip + chevron on the drop side.
    static func buildDropIn(_ d: World.DropIn) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: d.x, y: d.y)
        root.zRotation = d.dir
        root.zPosition = -460
        root.addChild(Art.fillRoundRect(-52, -42 + 8, 104, 84, 16, SKColor(white: 0, alpha: 0.22)))   // shadow
        root.addChild(Art.fillRoundRect(-52, -42, 104, 84, 16, SKColor(hex: 0x3a3550)))                // platform
        root.addChild(Art.fillRoundRect(-44, -34, 88, 68, 12, SKColor(hex: 0x565073)))                 // top face
        root.addChild(Art.fillRoundRect(44, -42, 8, 84, 4, Palette.gold))                              // coping (drop side)
        for i in -1...1 {                                                                              // chevrons -> drop dir
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 10 + CGFloat(i) * 0, y: 0))
            let cx = 8 + CGFloat(i) * 16
            p.move(to: CGPoint(x: cx - 8, y: -14)); p.addLine(to: CGPoint(x: cx + 6, y: 0)); p.addLine(to: CGPoint(x: cx - 8, y: 14))
            let n = SKShapeNode(path: p); n.strokeColor = SKColor(white: 1, alpha: 0.5); n.lineWidth = 4; n.lineCap = .round; n.fillColor = .clear
            root.addChild(n)
        }
        return root
    }

    /// A wandering dog or cat that scurries away from the skater.
    static func buildAnimal(_ a: Animal) -> SKNode {
        let root = SKNode()
        let s: CGFloat = a.dog ? 1.0 : 0.82
        let body = SKColor.hsl(a.hue, a.dog ? 0.35 : 0.10, a.dog ? 0.45 : 0.62)
        root.addChild({ let sh = SKShapeNode(ellipseOf: CGSize(width: 26 * s, height: 10 * s))
            sh.fillColor = SKColor(white: 0, alpha: 0.28); sh.strokeColor = .clear; return sh }())
        // legs
        root.addChild(Art.line(-7 * s, -2, -7 * s, -9 * s, 3, Palette.wall))
        root.addChild(Art.line(7 * s, -2, 7 * s, -9 * s, 3, Palette.wall))
        // body + tail + head
        root.addChild(Art.fillRoundRect(-11 * s, -20 * s, 22 * s, 13 * s, 6 * s, body))
        root.addChild(Art.line(-11 * s, -16 * s, -18 * s, -22 * s, 3, body))          // tail
        root.addChild(Art.circle(11 * s, -22 * s, 6 * s, body))                        // head
        if a.dog {
            root.addChild(Art.line(9 * s, -27 * s, 6 * s, -20 * s, 3, body))           // floppy ear
        } else {
            root.addChild(Art.line(8 * s, -27 * s, 6 * s, -32 * s, 2.5, body))         // pointy ears
            root.addChild(Art.line(14 * s, -27 * s, 16 * s, -32 * s, 2.5, body))
        }
        return root
    }

    /// Tunnel floor: the dark road running through the pipe. Roof is separate.
    static func buildTunnelFloor(_ tn: World.Tunnel) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: tn.x + tn.w / 2, y: tn.y + tn.h / 2)
        root.zPosition = -3
        let w = tn.w, h = tn.h
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, h, h / 2, SKColor(hex: 0x140f1e)))
        return root
    }

    /// The tunnel = a concrete PIPE/culvert you skate through: a rounded tube with a
    /// cylindrical sheen and a bright-rimmed dark opening at each end. Drawn at high
    /// zPosition (translucent) so you duck through it and the cops lose you.
    static func buildTunnelRoof(_ tn: World.Tunnel) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: tn.x + tn.w / 2, y: tn.y + tn.h / 2)
        root.zPosition = 8000
        let w = tn.w, h = tn.h
        // pipe body (capsule) — translucent so you see yourself inside
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, h, h / 2, SKColor(hex: 0x625c74, alpha: 0.72)))
        // cylindrical sheen along the top + shadow along the bottom
        root.addChild(Art.fillRoundRect(-w / 2 + 16, -h / 2 + 6, w - 32, h * 0.24, h * 0.12, SKColor(hex: 0x958db4, alpha: 0.55)))
        root.addChild(Art.fillRoundRect(-w / 2 + 16, h / 2 - h * 0.22, w - 32, h * 0.14, h * 0.07, SKColor(white: 0, alpha: 0.22)))
        // round openings at each end: bright concrete rim + black hole
        for sx: CGFloat in [-w / 2, w / 2] {
            let rim = SKShapeNode(ellipseOf: CGSize(width: 26, height: h + 4))
            rim.fillColor = SKColor(hex: 0x9c96b0); rim.strokeColor = .clear; rim.position = CGPoint(x: sx, y: 0)
            let hole = SKShapeNode(ellipseOf: CGSize(width: 16, height: h - 14))
            hole.fillColor = SKColor(hex: 0x08060f); hole.strokeColor = .clear; hole.position = CGPoint(x: sx, y: 0)
            root.addChild(rim); root.addChild(hole)
        }
        let tag = Art.label("TUNNEL", size: 16, color: Palette.cyan)
        tag.position = CGPoint(x: 0, y: h / 2 + 16)
        root.addChild(tag)
        return root
    }

    /// A raised funbox (its top edge is a grindable ledge added in World.rails).
    static func buildFunbox(_ f: World.Funbox) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: f.x + f.w / 2, y: f.y + f.h / 2)
        root.zPosition = -480
        let w = f.w, h = f.h
        root.addChild(Art.fillRoundRect(-w / 2, h / 2 - 4, w, 28, 12, SKColor(hex: 0x2c2740)))  // front skirt (height)
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, h, 16, SKColor(hex: 0x746e8c)))       // top face
        root.addChild(Art.fillRoundRect(-w / 2 + 8, -h / 2 + 8, w - 16, 8, 6, SKColor(white: 1, alpha: 0.12)))
        return root
    }

    /// A banked pyramid (concentric tiers). Top ledge grindable via World.rails.
    static func buildPyramid(_ p: World.Pyramid) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: p.x + p.w / 2, y: p.y + p.h / 2)
        root.zPosition = -490
        let w = p.w, h = p.h
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2 + 8, w, h, 20, SKColor(white: 0, alpha: 0.18)))       // shadow
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, h, 20, SKColor(hex: 0x4a4368)))                    // base bank
        root.addChild(Art.fillRoundRect(-w * 0.35, -h * 0.35, w * 0.70, h * 0.70, 16, SKColor(hex: 0x655d8c)))// mid
        root.addChild(Art.fillRoundRect(-w * 0.21, -h * 0.21, w * 0.42, h * 0.42, 12, SKColor(hex: 0x847da8)))// top flat
        return root
    }

    static func buildRail(_ rl: World.Rail) -> SKNode {
        let root = SKNode()
        root.zPosition = -400
        // shadow
        root.addChild(Art.fillRect(rl.x, rl.y + rl.h, rl.w, 8, SKColor(white: 0, alpha: 0.2)))
        // body
        root.addChild(Art.fillRoundRect(rl.x, rl.y, rl.w, rl.h, rl.pad ? 10 : 7, rl.col))
        // top highlight
        root.addChild(Art.fillRoundRect(rl.x, rl.y, rl.w, max(3, rl.h * 0.28), 6, SKColor(white: 1, alpha: 0.19)))
        // little support legs for true rails
        if !rl.pad {
            var s = rl.x + 16
            while s < rl.x + rl.w {
                root.addChild(Art.line(s, rl.y + rl.h, s, rl.y + rl.h + 14, 2, SKColor(white: 0, alpha: 0.19)))
                s += 40
            }
        }
        return root
    }

    static func buildPickup() -> SKNode {
        let root = SKNode()
        // shadow
        root.addChild({ let s = SKShapeNode(ellipseOf: CGSize(width: 36, height: 15))
            s.fillColor = SKColor(white: 0, alpha: 0.28); s.strokeColor = .clear; return s }())
        let icon = SKNode(); icon.position = CGPoint(x: 0, y: -26)
        icon.addChild(Art.line(-16, 10, 14, 10, 6, Palette.cyan))              // deck
        let stem = CGMutablePath(); stem.move(to: CGPoint(x: 14, y: 10)); stem.addLine(to: CGPoint(x: 18, y: -18)); stem.addLine(to: CGPoint(x: 30, y: -18))
        let stemN = SKShapeNode(path: stem); stemN.strokeColor = Palette.cyan; stemN.lineWidth = 6; stemN.lineCap = .round; stemN.fillColor = .clear
        icon.addChild(stemN)
        icon.addChild(Art.circle(-16, 16, 6, SKColor(hex: 0xeaf6ff)))
        icon.addChild(Art.circle(16, 16, 6, SKColor(hex: 0xeaf6ff)))
        root.addChild(icon)
        let tag = Art.label("▲ scooter", size: 13, color: Palette.volt); tag.position = CGPoint(x: 0, y: -46)
        root.addChild(tag)
        // gentle bob
        icon.run(.repeatForever(.sequence([.moveBy(x: 0, y: -6, duration: 0.5),
                                           .moveBy(x: 0, y: 6, duration: 0.5)])))
        return root
    }

    static func buildCoin() -> SKNode {
        let root = SKNode()
        let sh = SKShapeNode(ellipseOf: CGSize(width: 18, height: 7))
        sh.fillColor = SKColor(white: 0, alpha: 0.25); sh.strokeColor = .clear; sh.position = CGPoint(x: 0, y: 4)
        root.addChild(sh)
        let coin = SKNode(); coin.position = CGPoint(x: 0, y: -9)
        coin.addChild(Art.circle(0, 0, 10, Palette.gold))
        coin.addChild(Art.circle(0, 0, 6, SKColor(hex: 0xffe89a)))
        root.addChild(coin)
        coin.run(.repeatForever(.sequence([.scaleX(to: 0.25, duration: 0.45), .scaleX(to: 1, duration: 0.45)])))  // spin
        root.run(.repeatForever(.sequence([.moveBy(x: 0, y: -4, duration: 0.5), .moveBy(x: 0, y: 4, duration: 0.5)])))
        return root
    }

    static func buildLetter(_ ch: String) -> SKNode {
        let root = SKNode()
        let sh = SKShapeNode(ellipseOf: CGSize(width: 30, height: 11))
        sh.fillColor = SKColor(white: 0, alpha: 0.28); sh.strokeColor = .clear
        root.addChild(sh)
        let tile = SKNode(); tile.position = CGPoint(x: 0, y: -28)
        let box = SKShapeNode(path: Art.roundRectPath(-17, -21, 34, 42, 9))
        box.fillColor = Palette.coral; box.strokeColor = SKColor(white: 1, alpha: 0.5); box.lineWidth = 2
        tile.addChild(box)
        tile.addChild(Art.label(ch, size: 26, color: .white, font: "AvenirNext-Heavy"))
        root.addChild(tile)
        tile.run(.repeatForever(.sequence([.moveBy(x: 0, y: -6, duration: 0.6), .moveBy(x: 0, y: 6, duration: 0.6)])))
        return root
    }

    static func buildPed(_ pd: Ped) -> SKNode {
        let root = SKNode()
        // shadow
        root.addChild({ let s = SKShapeNode(ellipseOf: CGSize(width: 24, height: 10))
            s.fillColor = SKColor(white: 0, alpha: 0.3); s.strokeColor = .clear; return s }())
        // legs
        root.addChild(Art.line(-4, -2, -5, -14, 4, Palette.wall))
        root.addChild(Art.line(4, -2, 5, -14, 4, Palette.wall))
        // body
        root.addChild(Art.fillRoundRect(-9, -30, 18, 20, 7, SKColor.hsl(pd.hue, 0.45, 0.62)))
        // head
        root.addChild(Art.circle(0, -38, 7, SKColor(hex: 0xf0c9a0)))
        return root
    }

    static func buildCar(_ ca: Car) -> SKNode {
        let root = SKNode()
        root.addChild({ let s = SKShapeNode(ellipseOf: CGSize(width: 44, height: 18))
            s.fillColor = SKColor(white: 0, alpha: 0.28); s.strokeColor = .clear; return s }())
        root.addChild(Art.fillRoundRect(-18, -30, 36, 60, 10, ca.col))
        root.addChild(Art.fillRoundRect(-13, -20, 26, 16, 6, SKColor(hex: 0x0b0913, alpha: 0.67)))
        root.addChild(Art.fillRoundRect(-13, 6, 26, 14, 6, SKColor(hex: 0x0b0913, alpha: 0.67)))
        // headlights point in travel direction
        let hy: CGFloat = ca.dir > 0 ? 26 : -26
        root.addChild(Art.fillRect(-12, hy - 3, 7, 6, SKColor(hex: 0xffe07a)))
        root.addChild(Art.fillRect(5, hy - 3, 7, 6, SKColor(hex: 0xffe07a)))
        return root
    }

    static func buildGuard() -> SKNode {
        let root = SKNode()
        root.addChild({ let s = SKShapeNode(ellipseOf: CGSize(width: 26, height: 11))
            s.fillColor = SKColor(white: 0, alpha: 0.32); s.strokeColor = .clear; return s }())
        root.addChild(Art.line(-4, -2, -5, -15, 4, SKColor(hex: 0x1c1830)))
        root.addChild(Art.line(4, -2, 5, -15, 4, SKColor(hex: 0x1c1830)))
        root.addChild(Art.fillRoundRect(-10, -34, 20, 22, 7, SKColor(hex: 0x2f3aa0)))   // uniform
        root.addChild(Art.fillRect(-10, -26, 20, 4, SKColor(hex: 0xffd35e)))            // badge line
        root.addChild(Art.circle(0, -42, 7, SKColor(hex: 0xf0c9a0)))                    // head
        root.addChild(Art.topArc(0, -45, 8, SKColor(hex: 0x1c1830)))                    // cap
        root.addChild(Art.fillRect(-8, -46, 16, 3, SKColor(hex: 0x1c1830)))
        let bang = Art.label("!", size: 11, color: .white); bang.position = CGPoint(x: 0, y: -40)
        root.addChild(bang)
        return root
    }

    /// The player rig is rebuilt each frame from live state (cheap: one node).
    /// `face` orients the rider; `spin`/`flip` animate the trick; `moving` picks the
    /// rolling stance vs. the stopped (board-held-vertical) pose.
    static func playerRig(ride: Rideable, face: CGFloat, spin: CGFloat, flip: Bool,
                          airborne: Bool, moving: Bool, outfit: Outfit) -> SKNode {
        let spinner = SKNode()
        if airborne && (spin != 0 || flip) {
            spinner.zRotation = spin * 0.12
            if ride.anchor == .feet && flip {
                spinner.xScale = cos(spin * 0.5) < 0 ? -1 : 1
            }
        }

        let rig = SKNode()
        switch ride.kind {
        case .skateboard:
            if !airborne && !moving {
                stoppedSkater(into: rig, ride: ride, outfit: outfit)
            } else {
                boardUnderFeet(into: rig, ride: ride)
                skatingRider(into: rig, ride: ride, pushing: moving && !airborne, outfit: outfit)
            }
        case .scooter:
            scooterUnderFeet(into: rig, ride: ride)
            scooterRider(into: rig, ride: ride, pushing: moving && !airborne, outfit: outfit)
        case .bike:
            bikeRig(into: rig, ride: ride, outfit: outfit)
        case .surf:
            surfRig(into: rig, ride: ride, outfit: outfit)
        }
        if !airborne { rig.xScale = cos(face) < 0 ? -1 : 1 }   // face the way you roll
        spinner.addChild(rig)
        return spinner
    }

    /// Side-view BMX bike: two wheels, a frame, bars and seat, rider on the pedals.
    private static func bikeRig(into rig: SKNode, ride: Rideable, outfit: Outfit) {
        let d = ride.deck, hub = SKColor(hex: 0x9a94ad)
        rig.addChild(Art.circle(-15, 16, 9, ride.wheels)); rig.addChild(Art.circle(-15, 16, 3, hub))
        rig.addChild(Art.circle(15, 16, 9, ride.wheels));  rig.addChild(Art.circle(15, 16, 3, hub))
        rig.addChild(Art.line(-15, 16, 0, 8, 4, d))     // chainstay
        rig.addChild(Art.line(0, 8, -3, -8, 4, d))      // seat tube
        rig.addChild(Art.line(0, 8, 13, -6, 4, d))      // down tube
        rig.addChild(Art.line(-3, -8, 13, -6, 4, d))    // top tube
        rig.addChild(Art.line(15, 16, 13, -8, 4, d))    // fork
        rig.addChild(Art.line(13, -8, 13, -17, 4, d))   // stem
        rig.addChild(Art.line(7, -17, 19, -17, 4, d))   // handlebar
        rig.addChild(Art.fillRoundRect(-8, -11, 11, 4, 2, SKColor(hex: 0x1c1830)))  // seat
        let legC = SKColor(hex: outfit.legs), armC = SKColor(hex: outfit.body)
        rig.addChild(Art.line(-1, -16, -3, 4, 5, legC))   // legs on the pedals
        rig.addChild(Art.line(4, -16, 6, 4, 5, legC))
        torsoHead(into: rig, outfit: outfit)
        rig.addChild(Art.line(4, -33, 14, -17, 5, armC))  // arms to the bars
        rig.addChild(Art.line(1, -30, 13, -18, 5, armC))
    }

    /// Rider on a surfboard: a long board with a crouched, arms-out surf stance.
    private static func surfRig(into rig: SKNode, ride: Rideable, outfit: Outfit) {
        let board = SKShapeNode(ellipseOf: CGSize(width: 56, height: 12))
        board.fillColor = ride.deck; board.strokeColor = .clear; board.position = CGPoint(x: 0, y: 12)
        rig.addChild(board)
        rig.addChild(Art.fillRoundRect(-3, 8, 6, 8, 2, SKColor(hex: 0x37d6e6)))   // stripe/logo
        let legC = SKColor(hex: outfit.legs), armC = SKColor(hex: outfit.body)
        rig.addChild(Art.line(-8, -13, -10, 6, 5, legC))   // feet planted apart, knees bent
        rig.addChild(Art.line(9, -13, 11, 6, 5, legC))
        torsoHead(into: rig, outfit: outfit)
        rig.addChild(Art.line(-9, -32, -19, -27, 5, armC)) // arms out wide for balance
        rig.addChild(Art.line(9, -32, 19, -35, 5, armC))
    }

    /// Board lying flat under the feet (side profile), fixed under the rider.
    private static func boardUnderFeet(into rig: SKNode, ride: Rideable) {
        rig.addChild(Art.circle(-14, 17, 4, ride.wheels))
        rig.addChild(Art.circle(14, 17, 4, ride.wheels))
        rig.addChild(Art.fillRoundRect(-22, 7, 44, 9, 5, ride.deck))
        rig.addChild(Art.fillRoundRect(-22, 7, 44, 3, 3, SKColor(white: 1, alpha: 0.2)))
    }

    /// Rolling stance: knees bent, one foot pushing when moving.
    private static func skatingRider(into rig: SKNode, ride: Rideable, pushing: Bool, outfit: Outfit) {
        let legC = SKColor(hex: outfit.legs), armC = SKColor(hex: outfit.body)
        if pushing {
            rig.addChild(Art.line(-6, -16, -6, -2, 5, legC))   // front foot on deck
            rig.addChild(Art.line(4, -15, 13, -1, 5, legC))    // back foot kicking to push
        } else {
            rig.addChild(Art.line(-6, -16, -7, -2, 5, legC))   // both feet on the board
            rig.addChild(Art.line(6, -16, 7, -2, 5, legC))
        }
        torsoHead(into: rig, outfit: outfit)
        rig.addChild(Art.line(-9, -32, -16, -26, 5, armC))     // arms out for balance
        rig.addChild(Art.line(9, -32, 16, -38, 5, armC))
    }

    /// Stopped: standing, board held upright beside the rider.
    private static func stoppedSkater(into rig: SKNode, ride: Rideable, outfit: Outfit) {
        let legC = SKColor(hex: outfit.legs), armC = SKColor(hex: outfit.body)
        rig.addChild(Art.line(-4, -18, -4, -2, 5, legC))       // feet together
        rig.addChild(Art.line(4, -18, 4, -2, 5, legC))
        rig.addChild(Art.fillRoundRect(12, -38, 11, 52, 5, ride.deck))   // board held vertical
        rig.addChild(Art.fillRoundRect(12, -38, 4, 52, 3, SKColor(white: 1, alpha: 0.2)))
        rig.addChild(Art.circle(26, -25, 4, ride.wheels))
        rig.addChild(Art.circle(26, 3, 4, ride.wheels))
        torsoHead(into: rig, outfit: outfit)
        rig.addChild(Art.line(9, -32, 14, -22, 5, armC))       // hand holding the board
        rig.addChild(Art.line(-9, -32, -12, -22, 5, armC))
    }

    /// Side-view scooter under the feet: deck + two wheels + steering column + T-bar.
    private static func scooterUnderFeet(into rig: SKNode, ride: Rideable) {
        rig.addChild(Art.circle(-16, 18, 5, ride.wheels))              // rear wheel
        rig.addChild(Art.circle(18, 18, 5, ride.wheels))              // front wheel
        rig.addChild(Art.fillRoundRect(-22, 9, 44, 7, 3, ride.deck))  // deck
        rig.addChild(Art.fillRoundRect(-22, 9, 44, 2, 2, SKColor(white: 1, alpha: 0.2)))
        rig.addChild(Art.line(18, 14, 18, -40, 6, ride.deck))         // steering column
        rig.addChild(Art.line(9, -40, 27, -40, 6, ride.deck))         // handlebar
    }

    /// Rider standing on the scooter, hands forward on the bars (push kick when moving).
    private static func scooterRider(into rig: SKNode, ride: Rideable, pushing: Bool, outfit: Outfit) {
        let legC = SKColor(hex: outfit.legs), armC = SKColor(hex: outfit.body)
        if pushing {
            rig.addChild(Art.line(-4, -16, -4, 7, 5, legC))    // planted foot on deck
            rig.addChild(Art.line(6, -14, 15, 9, 5, legC))     // back foot pushing off
        } else {
            rig.addChild(Art.line(-5, -16, -5, 7, 5, legC))    // both feet on the deck
            rig.addChild(Art.line(5, -16, 5, 7, 5, legC))
        }
        torsoHead(into: rig, outfit: outfit)
        rig.addChild(Art.line(3, -34, 17, -40, 5, armC))       // arms reach to the bars
        rig.addChild(Art.line(1, -30, 15, -39, 5, armC))
    }

    /// Torso + head, wearing the chosen outfit (shirt colour + headgear style).
    private static func torsoHead(into rig: SKNode, outfit: Outfit) {
        rig.addChild(Art.fillRoundRect(-10, -38, 20, 24, 8, SKColor(hex: outfit.body)))
        rig.addChild(Art.fillRoundRect(-10, -38, 20, 6, 6, SKColor(white: 1, alpha: 0.15)))
        rig.addChild(Art.circle(0, -46, 8, Palette.skinTone))
        let hc = SKColor(hex: outfit.headHex)
        switch outfit.head {
        case .cap:
            rig.addChild(Art.topArc(0, -48, 9, hc))
            rig.addChild(Art.fillRect(-9, -49, 18, 3, hc))                       // brim
        case .helmet:
            rig.addChild(Art.circle(0, -47, 10, hc))                             // full shell
            rig.addChild(Art.fillRect(-11, -43, 22, 2.5, SKColor(white: 0, alpha: 0.25)))
        case .beanie:
            rig.addChild(Art.topArc(0, -49, 9, hc))
            rig.addChild(Art.fillRoundRect(-9, -50, 18, 5, 2, hc))               // fold band
        case .bare:
            break
        }
    }
}
