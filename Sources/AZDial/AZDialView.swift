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
    /// Rain tread — flowing wavy grooves and fine sipes carved into matte rubber.
    case rain
    /// Fine rain tread — denser, tighter-weaving variant of ``rain``.
    case diamond
    /// Tire tread — raised rubber lugs with carved grooves shaded for depth.
    case tread
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

    // MARK: Custom CoreGraphics tile

    /// A custom style drawn with CoreGraphics into a cached, horizontally-tiled image.
    ///
    /// Use this when you want a procedural surface without supplying image assets.
    /// The rendered tile is cached per `(id, colorScheme, dialHeight)`, so `draw` runs
    /// only once for each combination.
    ///
    /// - Parameters:
    ///   - id: Stable identifier, used for persistence and as the tile cache key.
    ///         Keep it unique per distinct appearance.
    ///   - tileWidth: Horizontal repeat width in points.
    ///   - draw: Renders one tile. The context has a **top-left origin** and is already
    ///           scaled for the display, so draw using point coordinates within `size`.
    ///           `size` is the tile size in points (its height matches the dial); the
    ///           `Bool` is `true` in dark mode.
    case drawn(id: String, tileWidth: CGFloat, draw: @Sendable (CGContext, CGSize, Bool) -> Void)

    // MARK: Helpers

    /// All built-in (non-tile) styles, in display order.
    public static let allBuiltin: [DialStyle] = [.rain, .diamond, .tread, .regacy, .midnight, .brass, .ocean, .shape, .varnia, .chrome, .hairline, .rubber]

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
        case .rain:     return "Rain"
        case .diamond:  return "Diamond"
        case .tread:    return "Tread"
        case .tile(let light, _, _, _): return light
        case .drawn(let id, _, _): return id
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
        case .rain:     return "rain"
        case .diamond:  return "diamond"
        case .tread:    return "tread"
        case .tile(let light, let dark, _, _): return "tile:\(light):\(dark ?? "")"
        case .drawn(let id, _, _): return "drawn:\(id)"
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
        case "rain":     return .rain
        case "diamond":  return .diamond
        case "tread":    return .tread
        default:         return nil
        }
    }

    /// Horizontal repeat width (points) for CoreGraphics-generated built-in tiles.
    /// `nil` for image-tile styles, which carry their own tile width.
    var generatedTileWidth: CGFloat? {
        switch self {
        case .varnia:   return 9
        case .chrome:   return 12
        case .hairline: return 6
        case .rubber:   return 14
        case .rain:     return 14
        case .diamond:  return 13
        case .tread:    return 22
        case .drawn(_, let tileWidth, _): return Swift.max(1, tileWidth)
        case .regacy, .midnight, .brass, .ocean, .shape, .tile:
            return nil
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
        title: "settings.preset.fine",
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
        title: "settings.preset.mild",
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
        title: "settings.preset.standard",
        tuning: .default
    )

    public static let light = AZDialInteractionTuningPreset(
        id: 3,
        title: "settings.preset.light",
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
        title: "settings.preset.fast",
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
        title: String = "settings.title",
        styleSectionTitle: String = "settings.style",
        sensitivitySectionTitle: String = "settings.sensitivity",
        testTitle: String = "settings.test",
        resetTitle: String = "settings.reset",
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var stylePreviewHeight = 44
    @ScaledMetric(relativeTo: .body) private var styleCardMinHeight = 76
    @ScaledMetric(relativeTo: .body) private var presetButtonMinHeight = 32
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

    private var styleGridColumns: [GridItem] {
        // 文字サイズが大きいときは列数を減らし、ラベル欠けを避ける。
        Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: resolvedStyleColumnCount)
    }

    private var presetGridColumns: [GridItem] {
        // プリセットは5個固定横並びだと詰まりやすいため、文字サイズに応じて折り返す。
        Array(repeating: GridItem(.flexible(), spacing: 6, alignment: .top), count: resolvedPresetColumnCount)
    }

    private var resolvedStyleColumnCount: Int {
        let configuredColumnCount = configuration.styleColumnCount
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large, .xLarge:
            return configuredColumnCount
        case .xxLarge, .xxxLarge, .accessibility1, .accessibility2:
            return Swift.min(2, configuredColumnCount)
        case .accessibility3, .accessibility4, .accessibility5:
            return 1
        @unknown default:
            return Swift.min(2, configuredColumnCount)
        }
    }

    private var resolvedPresetColumnCount: Int {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large, .xLarge:
            return 3
        case .xxLarge, .xxxLarge, .accessibility1, .accessibility2:
            return 2
        case .accessibility3, .accessibility4, .accessibility5:
            return 1
        @unknown default:
            return 2
        }
    }

    public var body: some View {
        List {
            Section {
                LazyVGrid(columns: styleGridColumns, spacing: 10) {
                    ForEach(configuration.styleCandidates, id: \.id) { candidate in
                        Button {
                            style = candidate
                        } label: {
                            VStack(spacing: 6) {
                                AZDialSurface(offset: 5, tickGap: 10, style: candidate)
                                    .frame(height: stylePreviewHeight)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                style.id == candidate.id ? Color.accentColor : Color.secondary.opacity(0.3),
                                                lineWidth: style.id == candidate.id ? 2.5 : 1
                                            )
                                    )
                                Text(verbatim: candidate.label)
                                    .font(.caption)
                                    .foregroundStyle(style.id == candidate.id ? .primary : .secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, minHeight: styleCardMinHeight, alignment: .top)
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
                    ViewThatFits(in: .vertical) {
                        HStack(alignment: .firstTextBaseline) {
                            localizedText(configuration.testTitle)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(verbatim: testValue.formatted(.number.grouping(.automatic)))
                                .font(.title3.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Button {
                                testValue = 0
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.caption.weight(.semibold))
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .accessibilityLabel(localizedText(configuration.resetTitle))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            localizedText(configuration.testTitle)
                                .font(.subheadline.weight(.semibold))
                            HStack(alignment: .center, spacing: 12) {
                                Text(verbatim: testValue.formatted(.number.grouping(.automatic)))
                                    .font(.title3.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                Button {
                                    testValue = 0
                                } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.caption.weight(.semibold))
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .accessibilityLabel(localizedText(configuration.resetTitle))
                            }
                        }
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

                LazyVGrid(columns: presetGridColumns, spacing: 6) {
                    ForEach(presets) { preset in
                        Button {
                            tuning = preset.tuning
                        } label: {
                            localizedText(preset.title)
                                .font(.caption)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, minHeight: presetButtonMinHeight)
                        }
                        .buttonStyle(.bordered)
                        .tint(currentPresetID == preset.id ? Color.accentColor : Color.gray)
                    }
                }

                tuningSlider(
                    title: "settings.pitch",
                    value: Binding(
                        get: { Double(tuning.pitch) },
                        set: { tuning.pitch = CGFloat($0) }
                    ),
                    range: 5...60,
                    step: 1,
                    valueText: "\(Int(tuning.pitch)) pt"
                )
                tuningSlider(
                    title: "settings.smoothing",
                    value: Binding(
                        get: { Double(tuning.velocitySmoothing) },
                        set: { tuning.velocitySmoothing = CGFloat($0) }
                    ),
                    range: 0.1...0.9,
                    step: 0.05,
                    valueText: String(format: "%.2f", Double(tuning.velocitySmoothing))
                )
                tuningSlider(
                    title: "settings.inertiaStartVelocity",
                    value: Binding(
                        get: { Double(tuning.inertiaStartVelocity) },
                        set: { tuning.inertiaStartVelocity = CGFloat($0) }
                    ),
                    range: 50...600,
                    step: 10,
                    valueText: "\(Int(tuning.inertiaStartVelocity)) pt/s"
                )
                tuningSlider(
                    title: "settings.fastSwipeVelocity",
                    value: Binding(
                        get: { Double(tuning.fastSwipeVelocity) },
                        set: { tuning.fastSwipeVelocity = CGFloat($0) }
                    ),
                    range: 600...3000,
                    step: 50,
                    valueText: "\(Int(tuning.fastSwipeVelocity)) pt/s"
                )
                Stepper(value: $tuning.slowSwipeMultiplier, in: 1...30) {
                    Text(verbatim: String(format: localizedString("settings.slowSwipeMultiplier"), tuning.slowSwipeMultiplier))
                }
                Stepper(value: $tuning.fastSwipeMultiplier, in: 10...200, step: 10) {
                    Text(verbatim: String(format: localizedString("settings.fastSwipeMultiplier"), tuning.fastSwipeMultiplier))
                }
                tuningSlider(
                    title: "settings.inertiaDecay",
                    value: Binding(
                        get: { Double(tuning.inertiaDecay) },
                        set: { tuning.inertiaDecay = CGFloat($0) }
                    ),
                    range: 0.85...0.98,
                    step: 0.01,
                    valueText: String(format: "%.2f", Double(tuning.inertiaDecay))
                )
                tuningSlider(
                    title: "settings.inertiaStopVelocity",
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
        .scrollIndicators(.hidden, axes: .vertical)
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
            ViewThatFits(in: .vertical) {
                HStack(alignment: .firstTextBaseline) {
                    localizedText(title)
                    Spacer()
                    Text(verbatim: valueText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    localizedText(title)
                    Text(verbatim: valueText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private func localizedText(_ key: String) -> Text {
        Text(localizedString(key))
    }

    private func localizedString(_ key: String) -> String {
        // 設定文字列はID-keyを優先し、未登録なら渡された文字列をそのまま表示する。
        NSLocalizedString(key, bundle: configuration.localizationBundle ?? .module, value: key, comment: "")
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
/// Position of the stepper (+/-) relative to the dial.
public enum AZDialStepperPosition: Hashable, Sendable {
    /// Stepper to the left of the dial (default).
    case left
    /// Stepper to the right of the dial.
    case right
    /// Stepper above the dial, centered on the dial.
    case top
    /// Stepper below the dial, centered on the dial.
    case bottom
}

public struct AZDialView: View {
    @Binding var value: Int
    let min: Int
    let max: Int
    let step: Int
    let stepperStep: Int
    let stepperPosition: AZDialStepperPosition
    var decimals: Int
    var style: DialStyle
    var dialWidth: CGFloat
    var tuning: AZDialInteractionTuning

    public init(
        value: Binding<Int>,
        min: Int,
        max: Int,
        step: Int,
        stepperStep: Int? = nil,
        stepperPosition: AZDialStepperPosition = .left,
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
        self.stepperStep = stepperStep ?? step
        self.stepperPosition = stepperPosition
        self.decimals = decimals
        self.style = style
        self.dialWidth = Swift.max(80, Swift.min(220, dialWidth))
        if let tuning {
            self.tuning = tuning
        } else {
            self.tuning = AZDialInteractionTuning(pitch: pitch)
        }
    }

    public var body: some View {
        let showStepper = stepperStep > 0
        switch stepperPosition {
        case .left:
            HStack(spacing: 12) {
                if showStepper { stepperView }
                dialView
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity, alignment: .trailing)
        case .right:
            HStack(spacing: 12) {
                dialView
                if showStepper { stepperView }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity, alignment: .trailing)
        case .top:
            VStack(spacing: 4) {
                if showStepper { stepperView }
                dialView
            }
            .frame(width: dialWidth)
            .frame(maxWidth: .infinity, alignment: .trailing)
        case .bottom:
            VStack(spacing: 4) {
                dialView
                if showStepper { stepperView }
            }
            .frame(width: dialWidth)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var dialView: some View {
        AZDialScrollArea(value: $value, min: min, max: max, step: step, style: style, tuning: tuning)
            .frame(width: dialWidth, height: 44)
    }

    private var stepperView: some View {
        Stepper("", value: $value, in: min...max, step: stepperStep)
            .labelsHidden()
            .frame(width: 94)
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
    @State private var lastVisualValue: Int? = nil
    @State private var didStopInertiaForCurrentTouch = false
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
                    didStopInertiaForCurrentTouch = true
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
                }
                .onEnded { _ in
                    didStopInertiaForCurrentTouch = false
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
                            }
                        }
                    }
                }
        )
        // 惰性停止は「タップ完了」ではなく「指を置いた瞬間」に反応させたい。
        // `TapGesture.onEnded` だと指を離すまで呼ばれないため、
        // `DragGesture(minimumDistance: 0)` の `onChanged` を touch down 相当として使う。
        // 通常のダイアルドラッグ側でも惰性を cancel するので、
        // 同じタッチで二重に stop しないよう `didStopInertiaForCurrentTouch` で抑制する。
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !didStopInertiaForCurrentTouch else { return }
                    didStopInertiaForCurrentTouch = true
                    stopInertia()
                }
                .onEnded { _ in
                    didStopInertiaForCurrentTouch = false
                }
        )
        .onAppear {
            resetVisualOffset()
        }
        .onChange(of: value) { newValue in
            applyVisualOffsetChange(to: newValue)
        }
        .onChange(of: tuning) { _ in
            resetVisualOffset()
        }
        .onChange(of: style.id) { _ in
            resetVisualOffset()
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

    /// 現在値を基準点として、表示用 offset の追跡状態を初期化する。
    ///
    /// スタイルや感度設定を変更した直後は、過去の見た目用 offset を引き継ぐより、
    /// その時点の値を新しい基準として扱った方が自然に見える。そのため offset は 0 に戻し、
    /// 次の値変更から差分として表示を動かす。
    private func resetVisualOffset() {
        lastVisualValue = value
        scrollOffset = 0
    }

    /// 値の変化量から、ダイアル表面に渡す表示用 offset を積み増す。
    ///
    /// 以前は「現在値そのもの」から絶対 offset を計算していたが、繰り返し模様では
    /// 周期の剰余によって、連続した Stepper の `+` 操作でも 2 回目以降が逆方向へ
    /// 戻ったように見えることがあった。
    ///
    /// ここでは値の差分だけを見て、表示 offset を少しずつ同じ方向へ積み増す。
    /// これにより `+` なら常に右方向、`-` なら常に左方向へ流れて見える。
    /// 操作感度としての `tuning.pitch` はドラッグ量から値への変換にだけ使い、
    /// 見た目の移動量とは切り分ける。
    private func applyVisualOffsetChange(to newValue: Int) {
        let oldValue = lastVisualValue ?? newValue
        lastVisualValue = newValue

        let rawStepDelta = CGFloat(newValue - oldValue) / CGFloat(step)
        guard rawStepDelta != 0 else { return }

        let direction: CGFloat = rawStepDelta > 0 ? -1 : 1
        let visibleStepCount = Swift.min(abs(rawStepDelta), 3)
        scrollOffset += direction * visualPitch * visibleStepCount
    }

    /// 表示専用の 1 回あたり移動量。
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
        case .varnia, .chrome, .hairline, .rubber, .rain, .diamond, .tread, .drawn:
            return style.generatedTileWidth ?? tickGap
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
            // All other built-in styles: CoreGraphics-generated tiles (cached).
            generatedTileBody()
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

    // MARK: - Generated tiles (CoreGraphics, cached)

    private static let tileScale: CGFloat = 3

    private struct TileKey: Hashable {
        let id: String
        let dark: Bool
        let h: Int
    }
    private static var tileCache: [TileKey: CGImage] = [:]

    private func generatedTileBody() -> some View {
        let isDark = colorScheme == .dark
        let mod = style.generatedTileWidth ?? 10
        return GeometryReader { geo in
            let h = geo.size.height
            let raw = (-offset).truncatingRemainder(dividingBy: mod)
            let xStart = (raw >= 0 ? raw : raw + mod) - mod
            let count = Int(ceil((geo.size.width - xStart) / mod)) + 1
            ZStack(alignment: .topLeading) {
                if let cg = Self.generatedTile(style: style, dark: isDark, heightPt: h) {
                    ForEach(0..<count, id: \.self) { i in
                        Image(decorative: cg, scale: Self.tileScale)
                            .resizable()
                            .frame(width: mod, height: h)
                            .offset(x: xStart + CGFloat(i) * mod)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
            .clipped()
        }
    }

    private static func generatedTile(style: DialStyle, dark: Bool, heightPt: CGFloat) -> CGImage? {
        let key = TileKey(id: style.id, dark: dark, h: Int(heightPt.rounded()))
        if let cached = tileCache[key] { return cached }
        guard let img = renderTile(style: style, dark: dark, heightPt: heightPt) else { return nil }
        tileCache[key] = img
        return img
    }

    // MARK: - Tile renderer

    /// RGB color set used while drawing a built-in tile.
    private struct Pal {
        var groove: (CGFloat, CGFloat, CGFloat)
        var dark:   (CGFloat, CGFloat, CGFloat)
        var bright: (CGFloat, CGFloat, CGFloat)
        var edge:   (CGFloat, CGFloat, CGFloat)
    }

    private static func palette(style: DialStyle, dark: Bool) -> Pal {
        func g(_ x: CGFloat) -> (CGFloat, CGFloat, CGFloat) { (x, x, x) }
        switch style {
        case .varnia:
            return dark ? Pal(groove: g(0.05), dark: g(0.11), bright: g(0.52), edge: g(0.88))
                        : Pal(groove: g(0.52), dark: g(0.62), bright: g(0.82), edge: g(1.0))
        case .chrome:
            return dark ? Pal(groove: g(0.03), dark: g(0.10), bright: (0.84, 0.87, 0.92), edge: g(1.0))
                        : Pal(groove: g(0.42), dark: g(0.52), bright: (0.90, 0.93, 0.97), edge: g(1.0))
        case .hairline:
            return dark ? Pal(groove: g(0.02), dark: g(0.30), bright: g(0.78), edge: g(1.0))
                        : Pal(groove: g(0.38), dark: g(0.65), bright: g(0.95), edge: g(1.0))
        case .rubber:
            return dark ? Pal(groove: g(0.07), dark: g(0.16), bright: g(0.34), edge: g(0.42))
                        : Pal(groove: g(0.30), dark: g(0.44), bright: g(0.64), edge: g(0.74))
        case .rain:
            // Matte rubber: groove = carved channel, dark = shadow wall, bright = face, edge = lit lip.
            return dark ? Pal(groove: g(0.04), dark: g(0.12), bright: g(0.30), edge: g(0.50))
                        : Pal(groove: g(0.12), dark: g(0.24), bright: g(0.44), edge: g(0.64))
        case .diamond:
            return dark ? Pal(groove: g(0.10), dark: g(0.18), bright: g(0.60), edge: g(1.0))
                        : Pal(groove: g(0.48), dark: g(0.60), bright: g(0.90), edge: g(1.0))
        case .tread:
            // Rubber: groove = deep recess shadow, dark = lug bottom, bright = lug face, edge = top highlight.
            return dark ? Pal(groove: g(0.05), dark: g(0.16), bright: g(0.46), edge: g(0.66))
                        : Pal(groove: g(0.14), dark: g(0.30), bright: g(0.56), edge: g(0.78))
        case .regacy, .midnight, .brass, .ocean, .shape, .tile, .drawn:
            return Pal(groove: g(0), dark: g(0), bright: g(0.5), edge: g(1))
        }
    }

    private static func cg(_ t: (CGFloat, CGFloat, CGFloat), _ space: CGColorSpace, _ a: CGFloat = 1) -> CGColor {
        CGColor(colorSpace: space, components: [t.0, t.1, t.2, a])!
    }

    private static func renderTile(style: DialStyle, dark: Bool, heightPt: CGFloat) -> CGImage? {
        let scale = tileScale
        let wPt = style.generatedTileWidth ?? 10
        let pxW = Int((wPt * scale).rounded())
        let pxH = Int((heightPt * scale).rounded())
        guard pxW > 0, pxH > 0 else { return nil }

        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: pxW, height: pxH,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Flip to a top-left origin so geometry matches SwiftUI.
        ctx.translateBy(x: 0, y: CGFloat(pxH))
        ctx.scaleBy(x: 1, y: -1)
        ctx.setShouldAntialias(true)
        ctx.interpolationQuality = .high

        let W = CGFloat(pxW)
        let H = CGFloat(pxH)
        let pal = palette(style: style, dark: dark)

        switch style {
        case .tread:
            drawTread(ctx, W: W, H: H, pal: pal, space: space)
        case .rain, .diamond:
            drawRain(ctx, W: W, H: H, pal: pal, space: space, spec: rainSpec(for: style))
        case .drawn(_, _, let draw):
            // Scale so the custom renderer can work in point coordinates (top-left origin).
            ctx.saveGState()
            ctx.scaleBy(x: scale, y: scale)
            draw(ctx, CGSize(width: wPt, height: heightPt), dark)
            ctx.restoreGState()
        default:
            drawRidge(ctx, style: style, W: W, H: H, pal: pal, space: space)
        }

        return ctx.makeImage()
    }

    /// Horizontal cylinder gradient across a ridge: dark → bright → (specular) → bright → dark.
    private static func cylinderGradient(_ pal: Pal, _ space: CGColorSpace, specular: Bool) -> CGGradient? {
        var comps: [CGFloat] = []
        var locs: [CGFloat] = []
        func add(_ t: (CGFloat, CGFloat, CGFloat), _ l: CGFloat) {
            comps += [t.0, t.1, t.2, 1]; locs.append(l)
        }
        if specular {
            add(pal.dark, 0.0); add(pal.bright, 0.34); add(pal.edge, 0.5); add(pal.bright, 0.66); add(pal.dark, 1.0)
        } else {
            add(pal.dark, 0.0); add(pal.bright, 0.5); add(pal.dark, 1.0)
        }
        return CGGradient(colorSpace: space, colorComponents: comps, locations: locs, count: locs.count)
    }

    /// Vertical shading (multiply) that darkens the ends so the surface reads as a 3-D cylinder.
    /// `edge` is the multiplier at the very top/bottom (lower = stronger darkening).
    private static func applyEndShading(_ ctx: CGContext, top: CGFloat, bottom: CGFloat, space: CGColorSpace, edge: CGFloat = 0.30) {
        let comps: [CGFloat] = [
            edge, edge, edge, 1,
            1.0,  1.0,  1.0,  1,
            1.0,  1.0,  1.0,  1,
            edge, edge, edge, 1,
        ]
        let locs: [CGFloat] = [0.0, 0.26, 0.74, 1.0]
        guard let grad = CGGradient(colorSpace: space, colorComponents: comps, locations: locs, count: 4) else { return }
        ctx.saveGState()
        ctx.setBlendMode(.multiply)
        ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: top), end: CGPoint(x: 0, y: bottom), options: [])
        ctx.restoreGState()
    }

    // MARK: Ridge styles (varnia / chrome / hairline / rubber)

    private static func drawRidge(_ ctx: CGContext, style: DialStyle, W: CGFloat, H: CGFloat, pal: Pal, space: CGColorSpace) {
        // Groove background (the empty top/bottom that gives the dial its rounded feel).
        ctx.setFillColor(cg(pal.groove, space))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

        let widthFrac: CGFloat
        let specular: Bool
        switch style {
        case .varnia:   widthFrac = 0.52; specular = true
        case .chrome:   widthFrac = 0.60; specular = true
        case .hairline: widthFrac = 0.34; specular = true
        case .rubber:   widthFrac = 0.74; specular = false
        default:        widthFrac = 0.52; specular = true
        }

        let rw = W * widthFrac
        let rx = (W - rw) / 2
        let vInset = H * 0.14            // empty groove above and below the ridge
        let capRect = CGRect(x: rx, y: vInset, width: rw, height: H - 2 * vInset)
        let radius = min(rw / 2, capRect.height / 2)
        let capsule = CGPath(roundedRect: capRect, cornerWidth: radius, cornerHeight: radius, transform: nil)

        ctx.saveGState()
        ctx.addPath(capsule)
        ctx.clip()

        if let grad = cylinderGradient(pal, space, specular: specular) {
            ctx.drawLinearGradient(
                grad,
                start: CGPoint(x: rx, y: H / 2),
                end:   CGPoint(x: rx + rw, y: H / 2),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
        applyEndShading(ctx, top: vInset, bottom: H - vInset, space: space)
        ctx.restoreGState()
    }

    // MARK: Rain tread

    /// Tunable parameters for the rain-tread renderer. ``DialStyle/rain`` and
    /// ``DialStyle/diamond`` share the renderer but differ only by these values.
    private struct RainSpec {
        var gwFrac: CGFloat          // groove (channel) width / tile width
        var ampFrac: CGFloat         // wave amplitude / tile width
        var wavelengthFrac: CGFloat  // wavelength / region height
        var nGrooves: Int            // grooves per tile
        var sipeLenFrac: CGFloat     // sipe length / groove spacing
        var sipeAmpFrac: CGFloat     // sipe diagonal slant / sipe length
        var sipeRowDiv: CGFloat      // smaller = denser sipe rows
    }

    private static func rainSpec(for style: DialStyle) -> RainSpec {
        switch style {
        case .diamond:
            // Denser, tighter, more strongly weaving grooves than rain.
            return RainSpec(gwFrac: 0.12, ampFrac: 0.24, wavelengthFrac: 0.40,
                            nGrooves: 3, sipeLenFrac: 0.6, sipeAmpFrac: 0.40, sipeRowDiv: 0.6)
        default: // .rain
            return RainSpec(gwFrac: 0.16, ampFrac: 0.16, wavelengthFrac: 0.62,
                            nGrooves: 2, sipeLenFrac: 0.5, sipeAmpFrac: 0.28, sipeRowDiv: 0.5)
        }
    }

    /// Summer/rain-tread look: flowing wavy longitudinal grooves carved into matte rubber,
    /// with fine diagonal sipes. Each groove has a lit lip and a shadowed wall for depth.
    private static func drawRain(_ ctx: CGContext, W: CGFloat, H: CGFloat, pal: Pal, space: CGColorSpace, spec: RainSpec) {
        let vInset = H * 0.04
        let regionTop = vInset
        let regionH = H - 2 * vInset

        // Raised rubber face (the lands between the grooves): a little brighter at the top
        // so the convex surface reads as catching light from above.
        let topHi: (CGFloat, CGFloat, CGFloat) = (
            (pal.bright.0 + pal.edge.0) / 2,
            (pal.bright.1 + pal.edge.1) / 2,
            (pal.bright.2 + pal.edge.2) / 2
        )
        let faceComps: [CGFloat] = [
            topHi.0,      topHi.1,      topHi.2,      1,
            pal.bright.0, pal.bright.1, pal.bright.2, 1,
            pal.bright.0, pal.bright.1, pal.bright.2, 1,
        ]
        let faceLocs: [CGFloat] = [0.0, 0.5, 1.0]
        if let faceGrad = CGGradient(colorSpace: space, colorComponents: faceComps, locations: faceLocs, count: 3) {
            ctx.drawLinearGradient(
                faceGrad,
                start: CGPoint(x: 0, y: 0),
                end:   CGPoint(x: 0, y: H),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        } else {
            ctx.setFillColor(cg(pal.bright, space))
            ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        }

        // Build one flowing groove centreline as a sine wave running top→bottom.
        func wavePath(gx: CGFloat, amp: CGFloat, wavelength: CGFloat, phase: CGFloat) -> CGMutablePath {
            let p = CGMutablePath()
            let steps = 28
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let y = regionTop + t * regionH
                let angle = 2 * Double.pi * Double((y - regionTop) / wavelength) + Double(phase)
                let x = gx + amp * CGFloat(sin(angle))
                if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                else { p.addLine(to: CGPoint(x: x, y: y)) }
            }
            return p
        }

        let gw = W * spec.gwFrac          // groove (channel) width
        let amp = W * spec.ampFrac        // wave amplitude
        let wavelength = regionH * spec.wavelengthFrac
        let nGrooves = spec.nGrooves
        let spacing = W / CGFloat(nGrooves)

        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        // Two grooves per tile, opposite phase so they weave together like the reference.
        for g in 0..<nGrooves {
            let phase = g.isMultiple(of: 2) ? CGFloat(0) : CGFloat.pi
            for k in [-1, 0, 1] {
                let gx = CGFloat(k) * W + (CGFloat(g) + 0.5) * spacing
                let path = wavePath(gx: gx, amp: amp, wavelength: wavelength, phase: phase)

                // Lit lip on the left of the channel (light from upper-left).
                ctx.saveGState()
                ctx.translateBy(x: -gw * 0.55, y: 0)
                ctx.addPath(path)
                ctx.setStrokeColor(cg(pal.edge, space, 0.7))
                ctx.setLineWidth(gw * 0.55)
                ctx.strokePath()
                ctx.restoreGState()

                // Shadow wall on the right of the channel.
                ctx.saveGState()
                ctx.translateBy(x: gw * 0.55, y: 0)
                ctx.addPath(path)
                ctx.setStrokeColor(cg(pal.dark, space, 0.85))
                ctx.setLineWidth(gw * 0.55)
                ctx.strokePath()
                ctx.restoreGState()

                // Dark carved channel on top.
                ctx.addPath(path)
                ctx.setStrokeColor(cg(pal.groove, space))
                ctx.setLineWidth(gw)
                ctx.strokePath()
            }
        }

        // Fine diagonal sipes on the rubber lands between grooves.
        let sipeRows = Swift.max(4, Int((regionH / (W * spec.sipeRowDiv)).rounded()))
        let sipeLen = spacing * spec.sipeLenFrac
        ctx.setLineWidth(Swift.max(0.8, W * 0.03))
        for s in 0...sipeRows {
            let y = regionTop + CGFloat(s) / CGFloat(sipeRows) * regionH
            for g in 0..<nGrooves {
                let lx = (CGFloat(g) + 1.0) * spacing            // land centre (between grooves)
                let sipe = CGMutablePath()
                sipe.move(to:    CGPoint(x: lx - sipeLen / 2, y: y - sipeLen * spec.sipeAmpFrac))
                sipe.addLine(to: CGPoint(x: lx + sipeLen / 2, y: y + sipeLen * spec.sipeAmpFrac))
                ctx.addPath(sipe)
                ctx.setStrokeColor(cg(pal.dark, space, 0.7))
                ctx.strokePath()
            }
        }

        applyEndShading(ctx, top: regionTop, bottom: regionTop + regionH, space: space, edge: 0.6)
    }

    // MARK: Tire tread

    /// Aggressive winter-tread look: interlocking angular (hex) lugs separated by a deep
    /// groove network, each lug raised with bevel shading and carved with fine sipes.
    private static func drawTread(_ ctx: CGContext, W: CGFloat, H: CGFloat, pal: Pal, space: CGColorSpace) {
        // Deepest recess: the groove network between the raised lugs.
        ctx.setFillColor(cg(pal.groove, space))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

        let vInset = H * 0.05
        let regionTop = vInset
        let regionH = H - 2 * vInset

        let grooveW = W * 0.16
        let rows = Swift.max(3, Int((regionH / (W * 0.74)).rounded()))
        let rowH = regionH / CGFloat(rows)
        let blockW = W - grooveW
        let blockH = rowH - grooveW * 0.55
        let pointH = blockH * 0.26                      // pointed top/bottom of the hexagon

        // Raised-lug vertical relief: top highlight → lit face → bottom shadow.
        let comps: [CGFloat] = [
            pal.edge.0,   pal.edge.1,   pal.edge.2,   1,
            pal.bright.0, pal.bright.1, pal.bright.2, 1,
            pal.dark.0,   pal.dark.1,   pal.dark.2,   1,
        ]
        let locs: [CGFloat] = [0.0, 0.34, 1.0]
        guard let grad = CGGradient(colorSpace: space, colorComponents: comps, locations: locs, count: 3) else { return }

        // Hexagon (pointed top & bottom) centred at (cx, cy).
        func hexPath(cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat) -> CGMutablePath {
            let x = cx - w / 2, y = cy - h / 2
            let p = CGMutablePath()
            p.move(to:    CGPoint(x: cx,     y: y))                 // top point
            p.addLine(to: CGPoint(x: x + w,  y: y + pointH))       // upper right
            p.addLine(to: CGPoint(x: x + w,  y: y + h - pointH))   // lower right
            p.addLine(to: CGPoint(x: cx,     y: y + h))            // bottom point
            p.addLine(to: CGPoint(x: x,      y: y + h - pointH))   // lower left
            p.addLine(to: CGPoint(x: x,      y: y + pointH))       // upper left
            p.closeSubpath()
            return p
        }

        func lug(cx: CGFloat, cy: CGFloat) {
            let w = blockW, h = blockH
            let x = cx - w / 2, y = cy - h / 2
            let path = hexPath(cx: cx, cy: cy, w: w, h: h)

            // Cast shadow into the groove below/right → makes the lug stand proud.
            ctx.saveGState()
            ctx.setShadow(
                offset: CGSize(width: w * 0.03, height: h * 0.11),
                blur: Swift.max(2, h * 0.10),
                color: cg((0, 0, 0), space, 0.6)
            )
            ctx.addPath(path)
            ctx.setFillColor(cg(pal.bright, space))
            ctx.fillPath()
            ctx.restoreGState()

            // Raised face.
            ctx.saveGState()
            ctx.addPath(path)
            ctx.clip()
            ctx.drawLinearGradient(
                grad,
                start: CGPoint(x: cx, y: y),
                end:   CGPoint(x: cx, y: y + h),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )

            // Sipes: fine carved chevrons across the lug (dark cut + bright lip below).
            let inset = w * 0.16
            let amp = h * 0.06
            for sy in [cy - h * 0.20, cy, cy + h * 0.20] {
                let cut = CGMutablePath()
                cut.move(to:    CGPoint(x: x + inset,     y: sy))
                cut.addLine(to: CGPoint(x: cx,            y: sy - amp))
                cut.addLine(to: CGPoint(x: x + w - inset, y: sy))
                ctx.setLineCap(.round)
                ctx.setLineJoin(.round)
                ctx.addPath(cut)
                ctx.setStrokeColor(cg(pal.edge, space, 0.45))
                ctx.setLineWidth(Swift.max(0.8, h * 0.03))
                ctx.translateBy(x: 0, y: Swift.max(0.8, h * 0.022))
                ctx.strokePath()
                ctx.translateBy(x: 0, y: -Swift.max(0.8, h * 0.022))
                ctx.addPath(cut)
                ctx.setStrokeColor(cg(pal.groove, space, 0.9))
                ctx.setLineWidth(Swift.max(1.0, h * 0.035))
                ctx.strokePath()
            }
            ctx.restoreGState()

            // Bevel: bright upper edges, dark lower edges → carved-in relief.
            let topEdge = CGMutablePath()
            topEdge.move(to:    CGPoint(x: x,     y: y + h - pointH))
            topEdge.addLine(to: CGPoint(x: x,     y: y + pointH))
            topEdge.addLine(to: CGPoint(x: cx,    y: y))
            topEdge.addLine(to: CGPoint(x: x + w, y: y + pointH))
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.addPath(topEdge)
            ctx.setStrokeColor(cg(pal.edge, space, 0.7))
            ctx.setLineWidth(Swift.max(1.0, h * 0.05))
            ctx.strokePath()

            let botEdge = CGMutablePath()
            botEdge.move(to:    CGPoint(x: x + w, y: y + pointH))
            botEdge.addLine(to: CGPoint(x: x + w, y: y + h - pointH))
            botEdge.addLine(to: CGPoint(x: cx,    y: y + h))
            botEdge.addLine(to: CGPoint(x: x,     y: y + h - pointH))
            ctx.addPath(botEdge)
            ctx.setStrokeColor(cg(pal.groove, space, 0.85))
            ctx.setLineWidth(Swift.max(1.0, h * 0.05))
            ctx.strokePath()
        }

        for r in 0..<rows {
            let cy = regionTop + (CGFloat(r) + 0.5) * rowH
            let stagger: CGFloat = r.isMultiple(of: 2) ? 0 : W / 2   // interlocking offset
            for k in [-1, 0, 1] {
                lug(cx: CGFloat(k) * W + stagger + W / 2, cy: cy)
            }
        }

        // Gentle cylinder shading only — keep the top row's highlights intact.
        applyEndShading(ctx, top: regionTop, bottom: regionTop + regionH, space: space, edge: 0.66)
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
                Text(verbatim: "Value: \(value)").font(.headline)
                ForEach(DialStyle.allBuiltin, id: \.id) { style in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: style.label).font(.caption).foregroundStyle(.secondary)
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
