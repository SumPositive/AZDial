// AZDialView.swift
// AZDial — SwiftUI scroll-wheel dial control
// Originally created by sumpo in 2012 as Objective-C AZDial.
// Rewritten in SwiftUI in 2025.

import SwiftUI

// MARK: - DialStyle

/// Visual style for AZDial.
///
/// Built-in styles use Canvas rendering.
/// Use `.tile(...)` to supply your own PDF/PNG image assets.
public enum DialStyle: Sendable {

    // MARK: Built-in styles

    /// Narrow machined knurling — the classic AZDial look.
    case varnia
    /// Polished chrome with high contrast.
    case chrome
    /// Ultra-fine hairline engraving.
    case hairline
    /// Rubber grip — wide, matte ridges.
    case rubber
    /// Classic AZDial knurling — image-tile reproduction of the original Objective-C design.
    case regacy
    /// Dark gunmetal knurling with high-contrast silver highlights.
    case midnight
    /// Warm brass knurling with champagne gold highlights.
    case brass
    /// Blue anodized aluminum knurling with ice-blue highlights.
    case ocean
    /// Shape-based knurling tile.
    case shape

    // MARK: Custom image tile

    /// Image-based tiling style.
    ///
    /// The image is tiled horizontally and scrolled with the dial.
    /// Supply separate asset names for light and dark mode.
    ///
    /// - Parameters:
    ///   - light: Asset name used in light mode.
    ///   - dark:  Asset name used in dark mode. Falls back to `light` if `nil`.
    ///   - tileWidth: Width of one tile repeat in points. Must match the image width.
    ///   - bundle: The bundle that contains the image assets. Pass `.module` for
    ///             assets in your own Swift package, or `nil` for the main bundle.
    case tile(light: String, dark: String? = nil, tileWidth: CGFloat = 20, bundle: Bundle? = nil)

    // MARK: Helpers

    /// All built-in (non-tile) styles, in display order.
    public static let allBuiltin: [DialStyle] = [.regacy, .midnight, .brass, .ocean, .shape, .varnia, .chrome, .hairline, .rubber]

    /// Human-readable label for display in settings UI.
    public var label: String {
        switch self {
        case .regacy:   return "Regacy"
        case .midnight: return "Midnight"
        case .brass:    return "Brass"
        case .ocean:    return "Ocean"
        case .shape:    return "Shape"
        case .varnia:   return "Varnia"
        case .chrome:   return "Chrome"
        case .hairline: return "Hairline"
        case .rubber:   return "Rubber"
        case .tile(let light, _, _, _): return light
        }
    }

    /// Stable string identifier for persistence.
    public var id: String {
        switch self {
        case .regacy:   return "regacy"
        case .midnight: return "midnight"
        case .brass:    return "brass"
        case .ocean:    return "ocean"
        case .shape:    return "shape"
        case .varnia:   return "varnia"
        case .chrome:   return "chrome"
        case .hairline: return "hairline"
        case .rubber:   return "rubber"
        case .tile(let light, let dark, _, _): return "tile:\(light):\(dark ?? "")"
        }
    }

    /// Restore a built-in style from its ``id``.
    public static func builtin(id: String) -> DialStyle? {
        switch id {
        case "regacy":   return .regacy
        case "midnight": return .midnight
        case "brass":    return .brass
        case "ocean":    return .ocean
        case "shape":    return .shape
        case "varnia":   return .varnia
        case "chrome":   return .chrome
        case "hairline": return .hairline
        case "rubber":   return .rubber
        default:         return nil
        }
    }
}

// MARK: - AZDialView

/// A horizontal scroll-wheel dial control.
///
/// ```swift
/// AZDialView(value: $weight, min: 300, max: 2000, step: 1, stepperStep: 10,
///            decimals: 1, style: .varnia)
/// ```
public struct AZDialView: View {
    @Binding var value: Int
    let min: Int
    let max: Int
    let step: Int
    let stepperStep: Int
    var decimals: Int
    var style: DialStyle
    var dialWidth: CGFloat
    var pitch: CGFloat

    public init(
        value: Binding<Int>,
        min: Int,
        max: Int,
        step: Int,
        stepperStep: Int,
        decimals: Int = 0,
        style: DialStyle = .shape,
        dialWidth: CGFloat = 220,
        pitch: CGFloat = 20
    ) {
        self._value = value
        self.min = min
        self.max = max
        self.step = step
        self.stepperStep = stepperStep
        self.decimals = decimals
        self.style = style
        self.dialWidth = Swift.max(80, Swift.min(220, dialWidth))
        self.pitch = Swift.max(5, pitch)
    }

    private var stepLabelText: String {
        if decimals == 0 {
            return "±\(stepperStep)"
        } else {
            let val = Double(stepperStep) / pow(10.0, Double(decimals))
            return "±\(String(format: "%.\(decimals)f", val))"
        }
    }

    public var body: some View {
        HStack(spacing: 12) {
            if stepperStep > 0 {
                Stepper("", value: $value, in: min...max, step: stepperStep)
                    .labelsHidden()
                    .frame(width: 94)
                    .overlay(alignment: .bottom) {
                        Text(stepLabelText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .offset(y: 14)
                            .allowsHitTesting(false)
                    }
            }
            AZDialScrollArea(value: $value, min: min, max: max, step: step, style: style, pitch: pitch)
                .frame(width: dialWidth)
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - AZDialScrollArea

private struct AZDialScrollArea: View {
    @Binding var value: Int
    let min: Int
    let max: Int
    let step: Int
    let style: DialStyle
    let pitch: CGFloat

    private let tickGap: CGFloat = 10.0

    @State private var scrollOffset: CGFloat = 0
    @State private var dragBase: CGFloat = 0
    @State private var dragAccumulator: CGFloat = 0
    @State private var lastDragTime: Double = 0
    @State private var smoothedVelocity: CGFloat = 0  // signed: positive = right drag
    @State private var inertiaTask: Task<Void, Never>? = nil
    @GestureState private var isDragging = false

    @Environment(\.colorScheme) private var colorScheme

    private var shadowOpacity: CGFloat { colorScheme == .dark ? 0.55 : 0.30 }
    private var rimBright:     CGFloat { colorScheme == .dark ? 0.55 : 0.50 }
    private var rimSoft:       CGFloat { colorScheme == .dark ? 0.18 : 0.12 }

    var body: some View {
        ZStack {
            AZDialSurface(offset: scrollOffset, tickGap: tickGap, style: style)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.black.opacity(0.72), Color.clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 44)
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.72)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 44)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(spacing: 0) {
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(rimBright), location: 0.00),
                        .init(color: Color.white.opacity(rimSoft),   location: 0.20),
                        .init(color: .clear,                          location: 1.00),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 9)
                Spacer()
                LinearGradient(
                    stops: [
                        .init(color: .clear,                          location: 0.00),
                        .init(color: Color.black.opacity(0.20),       location: 0.50),
                        .init(color: Color.black.opacity(0.48),       location: 1.00),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .overlay(alignment: .bottom) {
            Ellipse()
                .fill(Color.black.opacity(shadowOpacity))
                .frame(height: 18)
                .blur(radius: 8)
                .padding(.horizontal, 2)
                .offset(y: 10)
        }
        .gesture(
            DragGesture(minimumDistance: 1)
                .updating($isDragging) { _, state, _ in state = true }
                .onChanged { drag in
                    inertiaTask?.cancel()
                    inertiaTask = nil

                    let now = Date.timeIntervalSinceReferenceDate
                    if dragBase == 0 {
                        dragBase = drag.translation.width
                        lastDragTime = now
                        smoothedVelocity = 0
                    }
                    let delta = drag.translation.width - dragBase
                    dragBase = drag.translation.width

                    let dt = now - lastDragTime
                    lastDragTime = now
                    if dt > 0 {
                        let instant = delta / CGFloat(dt)  // signed
                        smoothedVelocity = smoothedVelocity * 0.6 + instant * 0.4
                    }

                    dragAccumulator += delta
                    let stepDelta = Int(dragAccumulator / pitch)
                    if stepDelta != 0 {
                        dragAccumulator -= CGFloat(stepDelta) * pitch
                        let newValue = Swift.max(min, Swift.min(max, value + stepDelta * step))
                        if newValue != value {
                            value = newValue
                            HapticsHelper.selection()
                        }
                    }
                    scrollOffset = offsetForValue(value)
                }
                .onEnded { _ in
                    dragBase = 0
                    dragAccumulator = 0
                    lastDragTime = 0

                    let v0 = smoothedVelocity
                    smoothedVelocity = 0
                    guard abs(v0) > 200 else { return }

                    let inertiaMultiplier: Int = abs(v0) > 1500 ? 100 : 10
                    inertiaTask = Task { @MainActor in
                        var v = v0
                        while !Task.isCancelled && abs(v) > 15 {
                            try? await Task.sleep(nanoseconds: 16_000_000)  // ~60fps
                            guard !Task.isCancelled else { break }
                            v *= 0.94
                            dragAccumulator += v / 60
                            let stepDelta = Int(dragAccumulator / pitch)
                            if stepDelta != 0 {
                                dragAccumulator -= CGFloat(stepDelta) * pitch
                                let newValue = Swift.max(min, Swift.min(max, value + stepDelta * step * inertiaMultiplier))
                                if newValue != value {
                                    value = newValue
                                    HapticsHelper.selection()
                                }
                                scrollOffset = offsetForValue(value)
                            }
                        }
                    }
                }
        )
        .onAppear {
            scrollOffset = offsetForValue(value)
        }
        .frame(height: 44)
        .accessibilityValue("\(value)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = Swift.min(max, value + step)
                HapticsHelper.selection()
            case .decrement:
                value = Swift.max(min, value - step)
                HapticsHelper.selection()
            @unknown default: break
            }
        }
    }

    private func offsetForValue(_ v: Int) -> CGFloat {
        -CGFloat(v - min) / CGFloat(step) * pitch
    }
}

// MARK: - AZDialSurface

/// The scrolling background of the dial.
///
/// Can be used standalone if you need only the visual background.
public struct AZDialSurface: View {
    public let offset: CGFloat
    public var tickGap: CGFloat = 16.0
    public var style: DialStyle = .varnia

    public init(offset: CGFloat, tickGap: CGFloat = 16.0, style: DialStyle = .shape) {
        self.offset = offset
        self.tickGap = tickGap
        self.style = style
    }

    @Environment(\.colorScheme) private var colorScheme

    public var body: some View {
        if case .regacy = style {
            tileBody(imageName: "AZDialTile_Regacy", tileWidth: 20, bundle: .module)
        } else if case .midnight = style {
            tileBody(imageName: "AZDialTile_Midnight", tileWidth: 20, bundle: .module)
        } else if case .brass = style {
            tileBody(imageName: "AZDialTile_Brass", tileWidth: 20, bundle: .module)
        } else if case .ocean = style {
            tileBody(imageName: "AZDialTile_Ocean", tileWidth: 20, bundle: .module)
        } else if case .shape = style {
            tileBody(imageName: "AZDialTile_Shape", tileWidth: 14, bundle: .module)
        } else if case .tile(let lightName, let darkName, let tileWidth, let bundle) = style {
            // Image-based tiling
            let imageName = colorScheme == .dark ? (darkName ?? lightName) : lightName
            tileBody(imageName: imageName, tileWidth: tileWidth, bundle: bundle)
        } else {
            // Canvas-based rendering for built-in styles
            Canvas { ctx, size in
                let w = size.width
                let h = size.height
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(groove))
                var x = (-offset).truncatingRemainder(dividingBy: tickGap)
                if x > 0 { x -= tickGap }
                while x < w {
                    drawOneRidge(ctx: ctx, x: x, topY: 0, h: h)
                    x += tickGap
                }
            }
        }
    }

    // MARK: - Tile helper

    private func tileBody(imageName: String, tileWidth: CGFloat, bundle: Bundle?) -> some View {
        GeometryReader { geo in
            let mod = Swift.max(tileWidth, 1)
            let raw = (-offset).truncatingRemainder(dividingBy: mod)
            let xStart = (raw >= 0 ? raw : raw + mod) - mod
            let count = Int(ceil((geo.size.width - xStart) / mod)) + 1
            ZStack(alignment: .topLeading) {
                ForEach(0..<count, id: \.self) { i in
                    Image(imageName, bundle: bundle)
                        .resizable()
                        .frame(width: mod, height: geo.size.height)
                        .offset(x: xStart + CGFloat(i) * mod)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
            .clipped()
        }
    }

    // MARK: - Palette

    private var groove: Color {
        switch style {
        case .varnia:
            return colorScheme == .dark ? Color(white: 0.05) : Color(white: 0.52)
        case .chrome:
            return colorScheme == .dark ? Color(white: 0.03) : Color(white: 0.42)
        case .hairline:
            return colorScheme == .dark ? Color(white: 0.02) : Color(white: 0.38)
        case .rubber:
            return colorScheme == .dark ? Color(white: 0.07) : Color(white: 0.30)
        case .regacy, .midnight, .brass, .ocean, .shape, .tile:
            return .clear
        }
    }

    private var ridgeDark: Color {
        switch style {
        case .varnia:
            return colorScheme == .dark ? Color(white: 0.11) : Color(white: 0.62)
        case .chrome:
            return colorScheme == .dark ? Color(white: 0.10) : Color(white: 0.52)
        case .hairline:
            return colorScheme == .dark ? Color(white: 0.30) : Color(white: 0.65)
        case .rubber:
            return colorScheme == .dark ? Color(white: 0.16) : Color(white: 0.44)
        case .regacy, .midnight, .brass, .ocean, .shape, .tile:
            return .clear
        }
    }

    private var ridgeBright: Color {
        switch style {
        case .varnia:
            return colorScheme == .dark ? Color(white: 0.52) : Color(white: 0.80)
        case .chrome:
            return colorScheme == .dark
                ? Color(red: 0.84, green: 0.87, blue: 0.92)
                : Color(red: 0.90, green: 0.93, blue: 0.97)
        case .hairline:
            return colorScheme == .dark ? Color(white: 0.78) : Color(white: 0.95)
        case .rubber:
            return colorScheme == .dark ? Color(white: 0.30) : Color(white: 0.62)
        case .regacy, .midnight, .brass, .ocean, .shape, .tile:
            return .clear
        }
    }

    private var ridgeEdge: Color {
        switch style {
        case .varnia:
            return colorScheme == .dark ? Color(white: 0.80) : Color.white
        case .chrome:
            return Color.white
        case .hairline:
            return Color.white
        case .rubber:
            return colorScheme == .dark ? Color(white: 0.38) : Color(white: 0.72)
        case .regacy, .midnight, .brass, .ocean, .shape, .tile:
            return .clear
        }
    }

    // MARK: - Ridge drawing

    private func drawOneRidge(ctx: GraphicsContext, x: CGFloat, topY: CGFloat, h: CGFloat) {
        switch style {

        case .varnia:
            let rw = tickGap * 0.46
            let rx = x - rw / 2
            ctx.fill(
                Path(CGRect(x: rx, y: topY, width: rw, height: h)),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: ridgeDark,   location: 0.00),
                        .init(color: ridgeBright, location: 0.50),
                        .init(color: ridgeDark,   location: 1.00),
                    ]),
                    startPoint: CGPoint(x: rx,      y: topY + h / 2),
                    endPoint:   CGPoint(x: rx + rw, y: topY + h / 2)
                )
            )
            ctx.fill(
                Path(CGRect(x: rx + rw * 0.15, y: topY, width: rw * 0.70, height: 1.2)),
                with: .color(ridgeEdge)
            )

        case .chrome:
            let rw = tickGap * 0.42
            let rx = x - rw / 2
            ctx.fill(
                Path(CGRect(x: rx, y: topY, width: rw, height: h)),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: ridgeDark,   location: 0.00),
                        .init(color: ridgeBright, location: 0.40),
                        .init(color: Color.white, location: 0.50),
                        .init(color: ridgeBright, location: 0.60),
                        .init(color: ridgeDark,   location: 1.00),
                    ]),
                    startPoint: CGPoint(x: rx,      y: topY + h / 2),
                    endPoint:   CGPoint(x: rx + rw, y: topY + h / 2)
                )
            )
            ctx.fill(
                Path(CGRect(x: rx + rw * 0.10, y: topY, width: rw * 0.80, height: 1.5)),
                with: .color(ridgeEdge)
            )

        case .hairline:
            let rw = tickGap * 0.16
            let rx = x - rw / 2
            ctx.fill(
                Path(CGRect(x: rx, y: topY, width: rw, height: h)),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: ridgeDark,   location: 0.00),
                        .init(color: ridgeBright, location: 0.50),
                        .init(color: ridgeDark,   location: 1.00),
                    ]),
                    startPoint: CGPoint(x: rx,      y: topY + h / 2),
                    endPoint:   CGPoint(x: rx + rw, y: topY + h / 2)
                )
            )

        case .rubber:
            let rw = tickGap * 0.65
            let rx = x - rw / 2
            ctx.fill(
                Path(CGRect(x: rx, y: topY, width: rw, height: h)),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: ridgeDark,   location: 0.00),
                        .init(color: ridgeBright, location: 0.50),
                        .init(color: ridgeDark,   location: 1.00),
                    ]),
                    startPoint: CGPoint(x: rx,      y: topY + h / 2),
                    endPoint:   CGPoint(x: rx + rw, y: topY + h / 2)
                )
            )

        case .regacy, .midnight, .brass, .ocean, .shape, .tile:
            break // handled by image path in body
        }
    }
}

// MARK: - HapticsHelper

enum HapticsHelper {
    @MainActor
    static func selection() {
#if os(iOS)
        let gen = UISelectionFeedbackGenerator()
        gen.selectionChanged()
#endif
    }
}

// MARK: - Preview

private struct AZDialPreview: View {
    @State private var value = 120
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Value: \(value)").font(.headline)
                ForEach(DialStyle.allBuiltin, id: \.id) { style in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(style.label).font(.caption).foregroundStyle(.secondary)
                        AZDialView(value: $value, min: 30, max: 300,
                                   step: 1, stepperStep: 10, style: style)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        #if os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color(.systemGroupedBackground))
        #endif
    }
}

#Preview {
    AZDialPreview()
}

