//  GarageView.swift
//  Rollverse — the Garage. A SwiftUI sheet over the game where you swap real parts
//  and watch the feel readout change, then ride out and feel it. GameScene reads the
//  same GarageStore for its movement numbers.

import SwiftUI

final class GarageStore: ObservableObject {
    @Published var showGarage = false
    @Published var skateSetup = Setup()
    @Published var scooterSetup = Setup()
    @Published var currentRide = "skateboard"     // the scene keeps this in sync
    @Published var coins = 0                       // wallet (future shop currency)

    enum Dial { case deck, wheels, trucks, bearings }

    func setup(for key: String) -> Setup { key == "scooter" ? scooterSetup : skateSetup }

    var current: Setup {
        get { setup(for: currentRide) }
        set { if currentRide == "scooter" { scooterSetup = newValue } else { skateSetup = newValue } }
    }

    func cycle(_ dial: Dial, _ delta: Int) {
        var s = current
        switch dial {
        case .deck:     s.deck = wrap(s.deck + delta, Gear.deck.count)
        case .wheels:   s.wheels = wrap(s.wheels + delta, Gear.wheels.count)
        case .trucks:   s.trucks = wrap(s.trucks + delta, Gear.trucks.count)
        case .bearings: s.bearings = wrap(s.bearings + delta, Gear.bearings.count)
        }
        current = s
    }
    private func wrap(_ i: Int, _ n: Int) -> Int { ((i % n) + n) % n }
}

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255)
    }
}

struct GarageView: View {
    @ObservedObject var store: GarageStore

    private var base: Rideable { Rideable.all[store.currentRide] ?? .skateboard }
    private var eff: Gear.Eff { Gear.effective(base: base, setup: store.current) }
    private var isScooter: Bool { store.currentRide == "scooter" }

    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            Color(hex: 0x0b0913).ignoresSafeArea()
            VStack(spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("GARAGE").font(.system(size: 24, weight: .black)).foregroundColor(.white)
                        Text("Tuning your \(base.label) — feel it next run")
                            .font(.system(size: 12)).foregroundColor(Color(hex: 0xa79fc4))
                    }
                    Spacer()
                    Button { store.showGarage = false } label: {
                        Text("Ride out ▶").font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: 0x1a0a06))
                            .padding(.horizontal, 20).padding(.vertical, 11)
                            .background(Capsule().fill(Color(hex: 0xff5c39)))
                    }
                }

                LazyVGrid(columns: cols, spacing: 12) {
                    dial("Deck",     Gear.deck[store.current.deck],      .deck)
                    dial("Wheels",   Gear.wheels[store.current.wheels],  .wheels)
                    dial(isScooter ? "Clamp" : "Trucks", Gear.trucks[store.current.trucks], .trucks)
                    dial("Bearings", Gear.bearings[store.current.bearings], .bearings)
                }

                HStack(spacing: 18) {
                    Text("FEEL").font(.system(size: 12, weight: .heavy)).foregroundColor(Color(hex: 0xa79fc4)).kerning(2)
                    stat("Speed", eff.speedBar, 0x37d6e6)
                    stat("Turn",  eff.turnBar,  0xc6ff42)
                    stat("Pop",   eff.popBar,   0xffce4a)
                    stat("Roll",  eff.rollBar,  0xa583ff)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x181426)))
            }
            .padding(18)
        }
        .presentationDetents([.large])
    }

    private func dial(_ title: String, _ opt: Gear.Opt, _ d: GarageStore.Dial) -> some View {
        HStack(spacing: 10) {
            arrow("chevron.left") { store.cycle(d, -1) }
            VStack(spacing: 1) {
                Text(title.uppercased()).font(.system(size: 10, weight: .heavy))
                    .foregroundColor(Color(hex: 0xa79fc4)).kerning(1.2)
                Text(opt.name).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                Text(opt.hint).font(.system(size: 11)).foregroundColor(Color(hex: 0x8a80ad))
            }
            .frame(maxWidth: .infinity)
            arrow("chevron.right") { store.cycle(d, 1) }
        }
        .padding(.vertical, 8).padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x181426))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08))))
    }

    private func arrow(_ system: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color(hex: 0x2a2440)))
        }
        .buttonStyle(.plain)
    }

    private func stat(_ label: String, _ v: CGFloat, _ hex: UInt32) -> some View {
        VStack(spacing: 5) {
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule().fill(Color(hex: hex)).frame(width: max(5, geo.size.width * v))
                }
            }
            .frame(height: 9)
        }
        .frame(maxWidth: .infinity)
    }
}
