// AZDialView.swift
// AZDial — SwiftUI scroll-wheel dial control
// Originally created by sumpo in 2012 as Objective-C AZDial.
// Rewritten in SwiftUI in 2025.

import SwiftUI

// MARK: - DialStyle

public enum DialStyle: Int, CaseIterable, Sendable {
    case soft = 0
    case machined = 1
    case chrome = 2
    case fine = 3
    case hairline = 4
    case rubber = 5
    case gold = 6
    case vintage = 7

    public var label: String {
        switch self {
        case .soft:     return String(localized: "DialStyle_Soft",     bundle: .module, defaultValue: "Soft")
        case .machined: return String(localized: "DialStyle_Machined", bundle: .module, defaultValue: "Machined")
        case .chrome:   return String(localized: "DialStyle_Chrome",   bundle: .module, defaultValue: "Chrome")
        case .fine:     return String(localized: "DialStyle_Fine",     bundle: .module, defaultValue: "Fine")
        case .hairline: return String(localized: "DialStyle_Hairline", bundle: .module, defaultValue: "Hairline")
        case .rubber:   return String(localized: "DialStyle_Rubber",   bundle: .module, defaultValue: "Rubber")
        case .gold:     return String(localized: "DialStyle_Gold",     bundle: .module, defaultValue: "Gold")
        case .vintage:  return String(localized: "DialStyle_Vintage",  bundle: .module, defaultValue: "Vintage")
        }
    }
}

// MARK: - AZDialView

public struct AZDialView: View {
    @Binding var value: Int
    let min: Int
    let max: Int
    let step: Int
    let stepperStep: Int
    var decimals: Int
    var style: DialStyle

    public init(
        value: Binding<Int>,
        min: Int,
        max: Int,
        step: Int,
        stepperStep: Int,
        decimals: Int = 0,
        style: DialStyle = .machined
    ) {
        self._value = value
        self.min = min
        self.max = max
        self.step = step
        self.stepperStep = stepperStep
        self.decimals = decimals
        self.style = style
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
        HStack(spacing: 6) {
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
            AZDialScrollArea(value: $value, min: min, max: max, step: step, style: style)
                .frame(width: 220)
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

    /// Drag sensitivity: pixels per step
    private let pitch: CGFloat = 15.0
    /// Visual tick spacing (px)
    private let tickGap: CGFloat = 10.0

    @State private var scrollOffset: CGFloat = 0
    @State private var dragBase: CGFloat = 0
    @GestureState private var isDragging = false

    @Environment(\.colorScheme) private var colorScheme

    private var shadowOpacity: CGFloat { colorScheme == .dark ? 0.55 : 0.30 }
    private var rimBright:     CGFloat { colorScheme == .dark ? 0.55 : 0.50 }
    private var rimSoft:       CGFloat { colorScheme == .dark ? 0.18 : 0.12 }

    var body: some View {
        ZStack {
            AZDialBack(offset: scrollOffset, tickGap: tickGap, style: style)
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
                    if dragBase == 0 {
                        scrollOffset = offsetForValue(value)
                        dragBase = drag.translation.width
                    }
                    let delta = drag.translation.width - dragBase
                    scrollOffset -= delta
                    dragBase = drag.translation.width

                    let targetSteps = Int(-scrollOffset / pitch)
                    let newValue = Swift.max(min, Swift.min(max, min + targetSteps * step))
                    if newValue != value {
                        value = newValue
                        HapticsHelper.selection()
                    }
                }
                .onEnded { _ in
                    dragBase = 0
                    scrollOffset = offsetForValue(value)
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

// MARK: - AZDialBack

public struct AZDialBack: View {
    public let offset: CGFloat
    public var tickGap: CGFloat = 16.0
    public var style: DialStyle = .machined

    public init(offset: CGFloat, tickGap: CGFloat = 16.0, style: DialStyle = .machined) {
        self.offset = offset
        self.tickGap = tickGap
        self.style = style
    }

    @Environment(\.colorScheme) private var colorScheme

    private var groove: Color {
        switch style {
        case .soft:
            return colorScheme == .dark ? Color(white: 0.20) : Color(white: 0.62)
        case .machined:
            return colorScheme == .dark ? Color(white: 0.05) : Color(white: 0.52)
        case .chrome:
            return colorScheme == .dark ? Color(white: 0.03) : Color(white: 0.42)
        case .fine:
            return colorScheme == .dark ? Color(white: 0.05) : Color(white: 0.52)
        case .hairline:
            return colorScheme == .dark ? Color(white: 0.02) : Color(white: 0.38)
        case .rubber:
            return colorScheme == .dark ? Color(white: 0.07) : Color(white: 0.30)
        case .gold:
            return colorScheme == .dark
                ? Color(red: 0.08, green: 0.06, blue: 0.02)
                : Color(red: 0.30, green: 0.22, blue: 0.08)
        case .vintage:
            return colorScheme == .dark
                ? Color(red: 0.14, green: 0.12, blue: 0.10)
                : Color(red: 0.48, green: 0.43, blue: 0.38)
        }
    }

    private var ridgeDark: Color {
        switch style {
        case .soft:
            return colorScheme == .dark ? Color(white: 0.32) : Color(white: 0.70)
        case .machined:
            return colorScheme == .dark ? Color(white: 0.11) : Color(white: 0.62)
        case .chrome:
            return colorScheme == .dark ? Color(white: 0.10) : Color(white: 0.52)
        case .fine:
            return colorScheme == .dark ? Color(white: 0.11) : Color(white: 0.62)
        case .hairline:
            return colorScheme == .dark ? Color(white: 0.30) : Color(white: 0.65)
        case .rubber:
            return colorScheme == .dark ? Color(white: 0.16) : Color(white: 0.44)
        case .gold:
            return colorScheme == .dark
                ? Color(red: 0.35, green: 0.26, blue: 0.06)
                : Color(red: 0.50, green: 0.38, blue: 0.12)
        case .vintage:
            return colorScheme == .dark
                ? Color(red: 0.22, green: 0.18, blue: 0.14)
                : Color(red: 0.58, green: 0.52, blue: 0.46)
        }
    }

    private var ridgeBright: Color {
        switch style {
        case .soft:
            return colorScheme == .dark ? Color(white: 0.62) : Color(white: 0.84)
        case .machined:
            return colorScheme == .dark ? Color(white: 0.52) : Color(white: 0.80)
        case .chrome:
            return colorScheme == .dark
                ? Color(red: 0.84, green: 0.87, blue: 0.92)
                : Color(red: 0.90, green: 0.93, blue: 0.97)
        case .fine:
            return colorScheme == .dark ? Color(white: 0.52) : Color(white: 0.80)
        case .hairline:
            return colorScheme == .dark ? Color(white: 0.78) : Color(white: 0.95)
        case .rubber:
            return colorScheme == .dark ? Color(white: 0.30) : Color(white: 0.62)
        case .gold:
            return colorScheme == .dark
                ? Color(red: 0.88, green: 0.72, blue: 0.28)
                : Color(red: 0.95, green: 0.82, blue: 0.40)
        case .vintage:
            return colorScheme == .dark
                ? Color(red: 0.50, green: 0.44, blue: 0.38)
                : Color(red: 0.80, green: 0.74, blue: 0.66)
        }
    }

    private var ridgeEdge: Color {
        switch style {
        case .soft:
            return colorScheme == .dark ? Color(white: 0.72) : Color(white: 0.92)
        case .machined:
            return colorScheme == .dark ? Color(white: 0.80) : Color.white
        case .chrome:
            return Color.white
        case .fine:
            return colorScheme == .dark ? Color(white: 0.80) : Color.white
        case .hairline:
            return Color.white
        case .rubber:
            return colorScheme == .dark ? Color(white: 0.38) : Color(white: 0.72)
        case .gold:
            return colorScheme == .dark
                ? Color(red: 1.0, green: 0.95, blue: 0.65)
                : Color(red: 1.0, green: 0.97, blue: 0.75)
        case .vintage:
            return colorScheme == .dark
                ? Color(red: 0.65, green: 0.58, blue: 0.50)
                : Color(red: 0.92, green: 0.87, blue: 0.80)
        }
    }

    public var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(groove))

            let topY:  CGFloat = 0
            let tickH: CGFloat = h

            var x = (-offset).truncatingRemainder(dividingBy: tickGap)
            if x > 0 { x -= tickGap }

            while x < w {
                drawOneRidge(ctx: ctx, x: x, topY: topY, h: tickH)
                x += tickGap
            }
        }
    }

    private func drawOneRidge(ctx: GraphicsContext, x: CGFloat, topY: CGFloat, h: CGFloat) {
        switch style {

        case .soft:
            let rw = tickGap * 0.58
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

        case .machined:
            let rw = tickGap * 0.46
            let rx = x - rw / 2
            let ridgeRect = CGRect(x: rx, y: topY, width: rw, height: h)
            ctx.fill(
                Path(ridgeRect),
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

        case .fine:
            let rw = tickGap * 0.28
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
                Path(CGRect(x: rx + rw * 0.15, y: topY, width: rw * 0.70, height: 1.0)),
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

        case .gold:
            let rw = tickGap * 0.75
            let rx = x - rw / 2
            ctx.fill(
                Path(CGRect(x: rx, y: topY, width: rw, height: h)),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: ridgeDark,   location: 0.00),
                        .init(color: ridgeBright, location: 0.40),
                        .init(color: ridgeEdge,   location: 0.50),
                        .init(color: ridgeBright, location: 0.60),
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

        case .vintage:
            let rw = tickGap * 0.75
            let rx = x - rw / 2
            ctx.fill(
                Path(CGRect(x: rx, y: topY, width: rw, height: h)),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: ridgeDark,   location: 0.00),
                        .init(color: ridgeBright, location: 0.28),
                        .init(color: ridgeBright, location: 0.72),
                        .init(color: ridgeDark,   location: 1.00),
                    ]),
                    startPoint: CGPoint(x: rx,      y: topY + h / 2),
                    endPoint:   CGPoint(x: rx + rw, y: topY + h / 2)
                )
            )
            ctx.fill(
                Path(CGRect(x: rx + rw * 0.20, y: topY, width: rw * 0.60, height: 0.8)),
                with: .color(ridgeEdge)
            )
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
        VStack(spacing: 20) {
            Text("Value: \(value)")
            AZDialView(value: $value, min: 30, max: 300, step: 1, stepperStep: 10)
                .padding(.horizontal)
            AZDialView(value: $value, min: 30, max: 300, step: 1, stepperStep: 0, style: .chrome)
                .padding(.horizontal)
            AZDialView(value: $value, min: 30, max: 300, step: 1, stepperStep: 0, style: .gold)
                .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    AZDialPreview()
}
