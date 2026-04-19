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

/// Interaction tuning values for ``AZDialView`` drag and inertia behavior.
public struct AZDialInteractionTuning: Codable, Sendable, Equatable {
    /// Points of horizontal drag required to move one value step.
    public var pitch: CGFloat
    /// Weight applied to the newest drag velocity sample.
    public var velocitySmoothing: CGFloat
    /// Minimum drag velocity that starts inertia after touch up.
    public var inertiaStartVelocity: CGFloat
    /// Velocity that switches inertia from slow to fast multiplier.
    public var fastSwipeVelocity: CGFloat
    /// Value-step multiplier used by slower inertial swipes.
    public var slowSwipeMultiplier: Int
    /// Value-step multiplier used by faster inertial swipes.
    public var fastSwipeMultiplier: Int
    /// Per-frame velocity multiplier during inertia. Higher values coast longer.
    public var inertiaDecay: CGFloat
    /// Velocity where inertia stops.
    public var inertiaStopVelocity: CGFloat

    public init(
        pitch: CGFloat = 20,
        velocitySmoothing: CGFloat = 0.4,
        inertiaStartVelocity: CGFloat = 200,
        fastSwipeVelocity: CGFloat = 1500,
        slowSwipeMultiplier: Int = 10,
        fastSwipeMultiplier: Int = 100,
        inertiaDecay: CGFloat = 0.94,
        inertiaStopVelocity: CGFloat = 15
    ) {
        self.pitch = Swift.max(5, pitch)
        self.velocitySmoothing = Swift.max(0, Swift.min(1, velocitySmoothing))
        self.inertiaStartVelocity = Swift.max(0, inertiaStartVelocity)
        self.fastSwipeVelocity = Swift.max(0, fastSwipeVelocity)
        self.slowSwipeMultiplier = Swift.max(1, slowSwipeMultiplier)
        self.fastSwipeMultiplier = Swift.max(1, fastSwipeMultiplier)
        self.inertiaDecay = Swift.max(0.80, Swift.min(0.99, inertiaDecay))
        self.inertiaStopVelocity = Swift.max(1, inertiaStopVelocity)
    }

    public static let `default` = AZDialInteractionTuning()
}

/// Built-in interaction presets for ``AZDialSettingsView``.
public struct AZDialInteractionTuningPreset: Identifiable, Sendable, Equatable {
    public let id: Int
    public let title: String
    public let tuning: AZDialInteractionTuning

    public init(id: Int, title: String, tuning: AZDialInteractionTuning) {
        self.id = id
        self.title = title
        self.tuning = tuning
    }

    public static let fine = AZDialInteractionTuningPreset(
        id: 0,
        title: "微細",
        tuning: AZDialInteractionTuning(
            pitch: 36,
            velocitySmoothing: 0.30,
            inertiaStartVelocity: 320,
            fastSwipeVelocity: 2200,
            slowSwipeMultiplier: 3,
            fastSwipeMultiplier: 20,
            inertiaDecay: 0.90,
            inertiaStopVelocity: 30
        )
    )

    public static let mild = AZDialInteractionTuningPreset(
        id: 1,
        title: "控えめ",
        tuning: AZDialInteractionTuning(
            pitch: 28,
            velocitySmoothing: 0.35,
            inertiaStartVelocity: 260,
            fastSwipeVelocity: 1800,
            slowSwipeMultiplier: 6,
            fastSwipeMultiplier: 50,
            inertiaDecay: 0.92,
            inertiaStopVelocity: 22
        )
    )

    public static let standard = AZDialInteractionTuningPreset(
        id: 2,
        title: "標準",
        tuning: .default
    )

    public static let light = AZDialInteractionTuningPreset(
        id: 3,
        title: "軽快",
        tuning: AZDialInteractionTuning(
            pitch: 14,
            velocitySmoothing: 0.50,
            inertiaStartVelocity: 140,
            fastSwipeVelocity: 1200,
            slowSwipeMultiplier: 15,
            fastSwipeMultiplier: 130,
            inertiaDecay: 0.95,
            inertiaStopVelocity: 12
        )
    )

    public static let fast = AZDialInteractionTuningPreset(
        id: 4,
        title: "高速",
        tuning: AZDialInteractionTuning(
            pitch: 9,
            velocitySmoothing: 0.60,
            inertiaStartVelocity: 90,
            fastSwipeVelocity: 900,
            slowSwipeMultiplier: 20,
            fastSwipeMultiplier: 180,
            inertiaDecay: 0.96,
            inertiaStopVelocity: 8
        )
    )

    public static let all: [AZDialInteractionTuningPreset] = [.fine, .mild, .standard, .light, .fast]
}

/// Display and behavior options for ``AZDialSettingsView``.
///
/// SwiftUI views are value types, so customize the settings sheet by passing a
/// configuration rather than subclassing the view.
public struct AZDialSettingsConfiguration {
    public var title: String
    public var styleSectionTitle: String
    public var sensitivitySectionTitle: String
    public var testTitle: String
    public var resetTitle: String
    public var styleCandidates: [DialStyle]
    public var styleColumnCount: Int
    public var testRange: ClosedRange<Int>
    public var localizationBundle: Bundle?

    public init(
        title: String = "ダイアル設定",
        styleSectionTitle: String = "スタイル",
        sensitivitySectionTitle: String = "操作感度",
        testTitle: String = "操作テスト",
        resetTitle: String = "リセット",
        styleCandidates: [DialStyle] = DialStyle.allBuiltin,
        styleColumnCount: Int = 3,
        testRange: ClosedRange<Int> = -999_999...999_999,
        localizationBundle: Bundle? = nil
    ) {
        self.title = title
        self.styleSectionTitle = styleSectionTitle
        self.sensitivitySectionTitle = sensitivitySectionTitle
        self.testTitle = testTitle
        self.resetTitle = resetTitle
        self.styleCandidates = styleCandidates
        self.styleColumnCount = Swift.max(1, styleColumnCount)
        self.testRange = testRange
        self.localizationBundle = localizationBundle ?? .module
    }

    public static let `default` = AZDialSettingsConfiguration()
}

/// A settings panel for choosing ``DialStyle`` and tuning ``AZDialView`` interaction behavior.
///
/// Present this view from your app's settings screen and persist the bound style
/// and ``AZDialInteractionTuning`` however your app stores settings.
public struct AZDialSettingsView: View {
    @Binding private var tuning: AZDialInteractionTuning
    @Binding private var style: DialStyle
    private let presets: [AZDialInteractionTuningPreset]
    private let configuration: AZDialSettingsConfiguration
    @State private var testValue: Int

    public init(
        tuning: Binding<AZDialInteractionTuning>,
        style: Binding<DialStyle>,
        presets: [AZDialInteractionTuningPreset] = AZDialInteractionTuningPreset.all,
        configuration: AZDialSettingsConfiguration = .default,
        testValue: Int = 0
    ) {
        self._tuning = tuning
        self._style = style
        self.presets = presets
        self.configuration = configuration
        self._testValue = State(initialValue: testValue)
    }

    public init(
        tuning: Binding<AZDialInteractionTuning>,
        style: DialStyle = .shape,
        presets: [AZDialInteractionTuningPreset] = AZDialInteractionTuningPreset.all,
        configuration: AZDialSettingsConfiguration = .default,
        testValue: Int = 0
    ) {
        self.init(tuning: tuning, style: .constant(style), presets: presets, configuration: configuration, testValue: testValue)
    }

    private var currentPresetID: Int? {
        presets.first { $0.tuning == tuning }?.id
    }

    public var body: some View {
        List {
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: configuration.styleColumnCount), spacing: 10) {
                    ForEach(configuration.styleCandidates, id: \.id) { candidate in
                        Button {
                            style = candidate
                        } label: {
                            VStack(spacing: 6) {
                                AZDialSurface(offset: 5, tickGap: 10, style: candidate)
                                    .frame(height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                style.id == candidate.id ? Color.accentColor : Color.secondary.opacity(0.3),
                                                lineWidth: style.id == candidate.id ? 2.5 : 1
                                            )
                                    )
                                Text(candidate.label)
                                    .font(.caption2)
                                    .foregroundStyle(style.id == candidate.id ? .primary : .secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                localizedText(configuration.styleSectionTitle)
            }

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        localizedText(configuration.testTitle)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(testValue.formatted(.number.grouping(.automatic)))
                            .font(.title3.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Button {
                            testValue = 0
                        } label: {
                            Label {
                                localizedText(configuration.resetTitle)
                            } icon: {
                                Image(systemName: "arrow.counterclockwise")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    AZDialView(
                        value: $testValue,
                        min: configuration.testRange.lowerBound,
                        max: configuration.testRange.upperBound,
                        step: 1,
                        stepperStep: 0,
                        style: style,
                        tuning: tuning
                    )
                }
                .padding(.vertical, 4)

                HStack(spacing: 6) {
                    ForEach(presets) { preset in
                        Button {
                            tuning = preset.tuning
                        } label: {
                            localizedText(preset.title)
                                .font(.caption)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(currentPresetID == preset.id ? Color.accentColor : Color.gray)
                    }
                }

                tuningSlider(
                    title: "ピッチ",
                    value: Binding(
                        get: { Double(tuning.pitch) },
                        set: { tuning.pitch = CGFloat($0) }
                    ),
                    range: 5...60,
                    step: 1,
                    valueText: "\(Int(tuning.pitch)) pt"
                )
                tuningSlider(
                    title: "なめらかさ",
                    value: Binding(
                        get: { Double(tuning.velocitySmoothing) },
                        set: { tuning.velocitySmoothing = CGFloat($0) }
                    ),
                    range: 0.1...0.9,
                    step: 0.05,
                    valueText: String(format: "%.2f", Double(tuning.velocitySmoothing))
                )
                tuningSlider(
                    title: "惰性開始速度",
                    value: Binding(
                        get: { Double(tuning.inertiaStartVelocity) },
                        set: { tuning.inertiaStartVelocity = CGFloat($0) }
                    ),
                    range: 50...600,
                    step: 10,
                    valueText: "\(Int(tuning.inertiaStartVelocity)) pt/s"
                )
                tuningSlider(
                    title: "高速判定速度",
                    value: Binding(
                        get: { Double(tuning.fastSwipeVelocity) },
                        set: { tuning.fastSwipeVelocity = CGFloat($0) }
                    ),
                    range: 600...3000,
                    step: 50,
                    valueText: "\(Int(tuning.fastSwipeVelocity)) pt/s"
                )
                Stepper(value: $tuning.slowSwipeMultiplier, in: 1...30) {
                    Text("低速倍率: \(tuning.slowSwipeMultiplier)x", bundle: .module)
                }
                Stepper(value: $tuning.fastSwipeMultiplier, in: 10...200, step: 10) {
                    Text("高速倍率: \(tuning.fastSwipeMultiplier)x", bundle: .module)
                }
                tuningSlider(
                    title: "惰性の残りやすさ",
                    value: Binding(
                        get: { Double(tuning.inertiaDecay) },
                        set: { tuning.inertiaDecay = CGFloat($0) }
                    ),
                    range: 0.85...0.98,
                    step: 0.01,
                    valueText: String(format: "%.2f", Double(tuning.inertiaDecay))
                )
                tuningSlider(
                    title: "惰性停止速度",
                    value: Binding(
                        get: { Double(tuning.inertiaStopVelocity) },
                        set: { tuning.inertiaStopVelocity = CGFloat($0) }
                    ),
                    range: 5...80,
                    step: 5,
                    valueText: "\(Int(tuning.inertiaStopVelocity)) pt/s"
                )
            } header: {
                localizedText(configuration.sensitivitySectionTitle)
            }
        }
        .navigationTitle(localizedText(configuration.title))
    }

    private func tuningSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        valueText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                localizedText(title)
                Spacer()
                Text(valueText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private func localizedText(_ key: String) -> Text {
        Text(LocalizedStringKey(key), bundle: configuration.localizationBundle)
    }
}

/// Backward-compatible name for the interaction tuning panel.
public typealias AZDialInteractionTuningView = AZDialSettingsView

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
    var tuning: AZDialInteractionTuning

    public init(
        value: Binding<Int>,
        min: Int,
        max: Int,
        step: Int,
        stepperStep: Int,
        decimals: Int = 0,
        style: DialStyle = .shape,
        dialWidth: CGFloat = 220,
        pitch: CGFloat = 20,
        tuning: AZDialInteractionTuning? = nil
    ) {
        self._value = value
        self.min = min
        self.max = max
        self.step = step
        self.stepperStep = stepperStep
        self.decimals = decimals
        self.style = style
        self.dialWidth = Swift.max(80, Swift.min(220, dialWidth))
        if let tuning {
            self.tuning = tuning
        } else {
            self.tuning = AZDialInteractionTuning(pitch: pitch)
        }
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
            AZDialScrollArea(value: $value, min: min, max: max, step: step, style: style, tuning: tuning)
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
    let tuning: AZDialInteractionTuning

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
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .gesture(
            DragGesture(minimumDistance: 1)
                .updating($isDragging) { _, state, _ in state = true }
                .onChanged { drag in
                    cancelInertia()

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
                        smoothedVelocity = smoothedVelocity * (1 - tuning.velocitySmoothing) + instant * tuning.velocitySmoothing
                    }

                    dragAccumulator += delta
                    let stepDelta = Int(dragAccumulator / tuning.pitch)
                    if stepDelta != 0 {
                        dragAccumulator -= CGFloat(stepDelta) * tuning.pitch
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
                    guard abs(v0) > tuning.inertiaStartVelocity else { return }

                    let inertiaMultiplier = abs(v0) > tuning.fastSwipeVelocity
                        ? tuning.fastSwipeMultiplier
                        : tuning.slowSwipeMultiplier
                    inertiaTask = Task { @MainActor in
                        var v = v0
                        while !Task.isCancelled && abs(v) > tuning.inertiaStopVelocity {
                            try? await Task.sleep(nanoseconds: 16_000_000)  // ~60fps
                            guard !Task.isCancelled else { break }
                            v *= tuning.inertiaDecay
                            dragAccumulator += v / 60
                            let stepDelta = Int(dragAccumulator / tuning.pitch)
                            if stepDelta != 0 {
                                dragAccumulator -= CGFloat(stepDelta) * tuning.pitch
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
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    stopInertia()
                }
        )
        .onAppear {
            scrollOffset = offsetForValue(value)
        }
        .onChange(of: value) { newValue in
            scrollOffset = offsetForValue(newValue)
        }
        .onChange(of: tuning) { _ in
            scrollOffset = offsetForValue(value)
        }
        .onChange(of: style.id) { _ in
            scrollOffset = offsetForValue(value)
        }
        .onDisappear {
            stopInertia()
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

    /// 現在値から、ダイアル表面に渡す表示用 offset を求める。
    ///
    /// ここでは `tuning.pitch` を直接使わず、`visualPitch` を使う。
    /// `tuning.pitch` は「何 pt ドラッグしたら 1 step 動くか」という操作感度の値で、
    /// ユーザ設定としてはそのまま維持したい。一方で、見た目のタイルや目盛りは
    /// スタイルごとに繰り返し周期があり、操作 pitch がその周期の整数倍に近いと
    /// 値は変わっているのに模様が同じ位置に戻って「止まって見える」。
    /// そのため、表示だけはスタイル周期に対して見えやすい移動量へ補正する。
    private func offsetForValue(_ v: Int) -> CGFloat {
        -CGFloat(v - min) / CGFloat(step) * visualPitch
    }

    /// 表示専用の 1 step あたり移動量。
    ///
    /// 操作感度としての `tuning.pitch` は変更しない。
    /// あくまで `AZDialSurface` に渡すスクロール量だけを補正することで、
    /// ユーザが設定した感度値と、各スタイルでの見た目の流れを切り分ける。
    private var visualPitch: CGFloat {
        optimizedVisualPitch(interactionPitch: tuning.pitch, repeatWidth: visualRepeatWidth)
    }

    /// 現在のスタイルが持つ、見た目上の横方向の繰り返し幅。
    ///
    /// 画像タイル系は画像幅そのものが周期になる。
    /// Canvas 描画系は `tickGap` ごとに同じ形の ridge を描くので、それを周期として扱う。
    /// この値を基準に、表示用 pitch が周期の整数倍にならないよう補正する。
    private var visualRepeatWidth: CGFloat {
        switch style {
        case .regacy, .midnight, .brass, .ocean:
            return 20
        case .shape:
            return 14
        case .tile(_, _, let tileWidth, _):
            return Swift.max(1, tileWidth)
        case .varnia, .chrome, .hairline, .rubber:
            return tickGap
        }
    }

    /// 操作用 pitch を、見た目で動きが分かる表示用 pitch に変換する。
    ///
    /// 例えば Canvas 系スタイルは `tickGap` ごとに同じ模様が繰り返される。
    /// `tuning.pitch` が 20pt、繰り返し幅が 10pt のような関係になると、
    /// 1 step 進んでも表面は 2 周期分動くだけなので、見た目にはほぼ静止して見える。
    ///
    /// また、余りが周期の後半に寄りすぎると、タイルの剰余表現によって
    /// 期待と逆方向に流れて見えることがある。そこで、余りが小さすぎる場合や
    /// 周期の半分を超える場合は、周期の約 37% に置き換えて、
    /// 「少しずつ同じ方向へ流れている」と認識しやすい表示量にする。
    ///
    /// これは見た目だけの補正なので、ドラッグ量から値へ変換する処理では
    /// 引き続き `tuning.pitch` を使う。
    private func optimizedVisualPitch(interactionPitch: CGFloat, repeatWidth: CGFloat) -> CGFloat {
        let period = Swift.max(1, repeatWidth)
        let rawRemainder = interactionPitch.truncatingRemainder(dividingBy: period)
        let remainder = rawRemainder >= 0 ? rawRemainder : rawRemainder + period
        let minimumVisibleDelta = period * 0.18
        let maximumForwardDelta = period * 0.50

        if remainder < minimumVisibleDelta || remainder > maximumForwardDelta {
            return period * 0.37
        }
        return remainder
    }

    private func stopInertia() {
        cancelInertia()
        smoothedVelocity = 0
        dragAccumulator = 0
    }

    private func cancelInertia() {
        inertiaTask?.cancel()
        inertiaTask = nil
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
