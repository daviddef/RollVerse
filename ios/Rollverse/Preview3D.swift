//  Preview3D.swift
//  Rollverse — a SceneKit spike exploring what an IMMERSIVE 3D half-pipe trick
//  could look like. Not the game engine — a prototype view you open from the
//  Garage to feel the 3D direction: a real curved half pipe, a skater running it
//  and flipping off the coping, and a camera you can drag to look around.

import SwiftUI
import SceneKit

// Half-pipe dimensions (metres-ish).
private let F: Float = 3      // flat-bottom half-width
private let R: Float = 3      // transition radius (= wall height)
private let L: Float = 11     // length of the pipe
private let coping: Float = F / 2 + R

private func surfaceHeight(_ x: Float) -> Float {
    let d = abs(x) - F / 2
    if d <= 0 { return 0 }
    if d >= R { return R }
    return R - (R * R - d * d).squareRoot()
}
private func lean(_ x: Float) -> Float {
    let d = max(0, abs(x) - F / 2)
    let a = asin(min(1, d / R))
    return x < 0 ? a : -a          // lean into the wall
}

struct Preview3D: View {
    @ObservedObject var store: GarageStore

    var body: some View {
        ZStack(alignment: .top) {
            PipeSceneView().ignoresSafeArea()
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("3D PREVIEW").font(.system(size: 22, weight: .black)).foregroundColor(.white)
                    Text("A peek at immersive 3D — drag to look around, pinch to zoom")
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Button { store.show3D = false } label: {
                    Text("Back ▶").font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Capsule().fill(Color(.sRGB, red: 1, green: 0.36, blue: 0.22)))
                }
            }
            .padding(18)
        }
        .statusBarHidden(true)
    }
}

private struct PipeSceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        v.scene = buildScene()
        v.allowsCameraControl = true
        v.autoenablesDefaultLighting = false
        v.antialiasingMode = .multisampling4X
        v.backgroundColor = UIColor(red: 0.16, green: 0.12, blue: 0.30, alpha: 1)
        return v
    }
    func updateUIView(_ uiView: SCNView, context: Context) {}

    private func buildScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = duskGradient()

        // --- ground ---
        let floor = SCNFloor()
        floor.reflectivity = 0.06
        floor.firstMaterial?.diffuse.contents = UIColor(red: 0.30, green: 0.28, blue: 0.38, alpha: 1)
        let floorNode = SCNNode(geometry: floor)
        floorNode.position.y = -0.72
        scene.rootNode.addChildNode(floorNode)

        // --- half pipe ---
        scene.rootNode.addChildNode(buildPipe())

        // --- skater ---
        let skater = buildSkater()
        scene.rootNode.addChildNode(skater)
        skater.runAction(.repeatForever(runSequence()))

        // --- camera ---
        let cam = SCNNode(); cam.camera = SCNCamera()
        cam.camera?.fieldOfView = 55
        cam.camera?.zNear = 0.1; cam.camera?.zFar = 200
        cam.position = SCNVector3(9.5, 6.5, 12)
        cam.look(at: SCNVector3(0, 1.4, 0))
        scene.rootNode.addChildNode(cam)
        scene.rootNode.name = "root"

        // --- lights ---
        let sun = SCNNode(); sun.light = SCNLight(); sun.light?.type = .directional
        sun.light?.intensity = 900; sun.light?.castsShadow = true
        sun.light?.color = UIColor(red: 1, green: 0.95, blue: 0.9, alpha: 1)
        sun.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 5, 0)
        scene.rootNode.addChildNode(sun)
        let amb = SCNNode(); amb.light = SCNLight(); amb.light?.type = .ambient
        amb.light?.intensity = 350; amb.light?.color = UIColor(red: 0.6, green: 0.55, blue: 0.8, alpha: 1)
        scene.rootNode.addChildNode(amb)
        let rim = SCNNode(); rim.light = SCNLight(); rim.light?.type = .omni
        rim.light?.intensity = 500; rim.light?.color = UIColor(red: 0.22, green: 0.84, blue: 0.9, alpha: 1)
        rim.position = SCNVector3(-8, 5, -6)
        scene.rootNode.addChildNode(rim)

        return scene
    }

    private func buildPipe() -> SCNNode {
        let path = UIBezierPath()
        var pts: [CGPoint] = []
        let steps = 16
        for i in 0...steps {                                   // left transition
            let a = CGFloat.pi + (CGFloat.pi / 2) * CGFloat(i) / CGFloat(steps)
            pts.append(CGPoint(x: CGFloat(-F / 2) + CGFloat(R) * cos(a), y: CGFloat(R) + CGFloat(R) * sin(a)))
        }
        for i in 0...steps {                                   // right transition
            let a = 1.5 * CGFloat.pi + (CGFloat.pi / 2) * CGFloat(i) / CGFloat(steps)
            pts.append(CGPoint(x: CGFloat(F / 2) + CGFloat(R) * cos(a), y: CGFloat(R) + CGFloat(R) * sin(a)))
        }
        path.move(to: pts[0])
        for p in pts.dropFirst() { path.addLine(to: p) }
        path.addLine(to: CGPoint(x: CGFloat(coping), y: -0.7))
        path.addLine(to: CGPoint(x: CGFloat(-coping), y: -0.7))
        path.close()

        let shape = SCNShape(path: path, extrusionDepth: CGFloat(L))
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(red: 0.42, green: 0.40, blue: 0.54, alpha: 1)
        mat.roughness.contents = 0.85
        shape.materials = [mat]
        let node = SCNNode(geometry: shape)
        node.position = SCNVector3(0, 0, -L / 2)

        // metal coping pipes on each lip
        for sx in [-coping, coping] {
            let c = SCNCylinder(radius: 0.09, height: CGFloat(L))
            c.firstMaterial?.diffuse.contents = UIColor(white: 0.85, alpha: 1)
            c.firstMaterial?.metalness.contents = 0.9; c.firstMaterial?.roughness.contents = 0.25
            let cn = SCNNode(geometry: c)
            cn.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)     // lie along z
            cn.position = SCNVector3(sx, R, 0)
            node.addChildNode(cn)
        }
        return node
    }

    private func buildSkater() -> SCNNode {
        let root = SCNNode()
        func box(_ w: Float, _ h: Float, _ d: Float, _ color: UIColor, _ y: Float) -> SCNNode {
            let b = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(d), chamferRadius: 0.04)
            b.firstMaterial?.diffuse.contents = color
            let n = SCNNode(geometry: b); n.position.y = y; return n
        }
        root.addChildNode(box(0.75, 0.1, 0.26, UIColor(red: 1, green: 0.36, blue: 0.22, alpha: 1), 0.06)) // board
        root.addChildNode(box(0.28, 0.5, 0.2, UIColor(red: 0.94, green: 0.30, blue: 0.23, alpha: 1), 0.38)) // body
        let head = SCNSphere(radius: 0.14)
        head.firstMaterial?.diffuse.contents = UIColor(red: 0.95, green: 0.81, blue: 0.67, alpha: 1)
        let hn = SCNNode(geometry: head); hn.position.y = 0.72; root.addChildNode(hn)
        root.pivot = SCNMatrix4MakeTranslation(0, 0, 0)   // rotate around the board
        return root
    }

    // A continuous half-pipe run: carve up one wall, flip off the coping, back down,
    // across, up the other wall, flip, repeat.
    private func runSequence() -> SCNAction {
        func ground(_ x: Float) -> SCNAction {
            .group([.move(to: SCNVector3(x, surfaceHeight(x) + 0.3, 0), duration: 0.26),
                    .rotateTo(x: 0, y: 0, z: CGFloat(lean(x)), duration: 0.26, usesShortestUnitArc: true)])
        }
        func air(_ side: Float) -> SCNAction {
            .sequence([
                .group([.move(to: SCNVector3(side * (coping + 0.5), R + 1.1, 0), duration: 0.3),
                        .rotateBy(x: 0, y: 0, z: CGFloat(-side) * 2 * .pi, duration: 0.3)]),
                .move(to: SCNVector3(side * coping, R + 0.3, 0), duration: 0.2),
            ])
        }
        return .sequence([
            ground(0), ground(-2), ground(-3.4), ground(-4.5),
            air(-1),
            ground(-3.4), ground(-2), ground(0),
            ground(2), ground(3.4), ground(4.5),
            air(1),
            ground(3.4), ground(2),
        ])
    }

    private func duskGradient() -> UIImage {
        let size = CGSize(width: 8, height: 400)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [UIColor(red: 0.14, green: 0.10, blue: 0.27, alpha: 1).cgColor,
                          UIColor(red: 0.23, green: 0.16, blue: 0.33, alpha: 1).cgColor,
                          UIColor(red: 0.35, green: 0.25, blue: 0.37, alpha: 1).cgColor] as CFArray
            let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.6, 1])!
            ctx.cgContext.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        }
    }
}
