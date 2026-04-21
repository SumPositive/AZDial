import SwiftUI
import AZDial

struct DemoView: View {
    @State private var selectedStyle: DialStyle = .shape
    @State private var value1 = 120     // 体重 60.0 kg (×10)
    @State private var value2 = 130     // 収縮期血圧
    @State private var value3 = 170     // 身長 cm
    @State private var value4 = 0       // 0 to 100
    @State private var interactionTuning = AZDialInteractionTuning.default
    @State private var isDialSettingsPresented = false

    var body: some View {
        NavigationStack {
            List {

                // MARK: - ダイアル設定
                Section {
                    Button {
                        isDialSettingsPresented = true
                    } label: {
                        Label("demo.settings.open", systemImage: "slider.horizontal.3")
                    }
                    Text("demo.settings.api")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("demo.settings.contribute")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } header: {
                    Text("settings.title")
                }

                // MARK: - 小数点あり（体重）
                Section {
                    HStack {
                        Text("demo.weight")
                        Spacer()
                        Text(verbatim: String(format: "%.1f kg", Double(value1) / 10))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    AZDialView(
                        value: $value1,
                        min: 200,
                        max: 2000,
                        step: 1,
                        stepperStep: 10,
                        decimals: 1,
                        style: selectedStyle,
                        tuning: interactionTuning
                    )
                } header: {
                    Text("demo.decimalStepper")
                }

                // MARK: - 整数（血圧）
                Section {
                    HStack {
                        Text("demo.systolicBloodPressure")
                        Spacer()
                        Text(verbatim: "\(value2) mmHg")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    AZDialView(
                        value: $value2,
                        min: 60,
                        max: 250,
                        step: 1,
                        stepperStep: 5,
                        style: selectedStyle,
                        tuning: interactionTuning
                    )
                } header: {
                    Text("demo.integerStepper")
                }

                // MARK: - ステッパー非表示
                Section {
                    HStack {
                        Text("demo.height")
                        Spacer()
                        Text(verbatim: "\(value3) cm")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    AZDialView(
                        value: $value3,
                        min: 100,
                        max: 250,
                        step: 1,
                        stepperStep: 0,
                        style: selectedStyle,
                        tuning: interactionTuning
                    )
                } header: {
                    Text("demo.noStepper")
                }

                // MARK: - 範囲 0〜100
                Section {
                    HStack {
                        Text("demo.level")
                        Spacer()
                        Text(verbatim: "\(value4)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    AZDialView(
                        value: $value4,
                        min: 0,
                        max: 100,
                        step: 1,
                        stepperStep: 10,
                        style: selectedStyle,
                        tuning: interactionTuning
                    )
                } header: {
                    Text("demo.range0100")
                }

                // MARK: - dialWidth
                Section {
                    ForEach([80, 120, 160, 220], id: \.self) { width in
                        HStack {
                            Text(verbatim: "\(width) pt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 48, alignment: .leading)
                            AZDialView(
                                value: $value4,
                                min: 0,
                                max: 100,
                                step: 1,
                                stepperStep: 10,
                                style: selectedStyle,
                                dialWidth: CGFloat(width),
                                tuning: interactionTuning
                            )
                        }
                    }
                } header: {
                    Text("demo.dialWidth")
                }

                // MARK: - ジェスチャー独立性テスト
                Section {
                    Text("demo.gesture.note")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ZStack {
                        ScrollView(.horizontal, showsIndicators: true) {
                            HStack(spacing: 0) {
                                ForEach(0..<6, id: \.self) { i in
                                    Text(verbatim: String(format: String(localized: "demo.page"), i + 1))
                                        .frame(width: UIScreen.main.bounds.width - 32, height: 80)
                                        .background(i.isMultiple(of: 2) ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        AZDialView(
                            value: $value4,
                            min: 0,
                            max: 100,
                            step: 1,
                            stepperStep: 10,
                            style: selectedStyle,
                            tuning: interactionTuning
                        )
                    }
                } header: {
                    Text("demo.gesture.title")
                }

                // MARK: - 画像タイル（使い方の案内）
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("demo.customTile.note")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(verbatim: """
                            AZDialView(
                              value: $value,
                              min: 0, max: 100,
                              step: 1, stepperStep: 10,
                              style: .tile(
                                light: "DialTile_Oval",
                                dark: "DialTile_Oval_Dark",
                                tileWidth: 20
                              )
                            )
                            """)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("demo.customTile.title")
                }
            }
            .navigationTitle(Text(verbatim: "AZDial Demo"))
            .sheet(isPresented: $isDialSettingsPresented) {
                NavigationStack {
                    AZDialSettingsView(tuning: $interactionTuning, style: $selectedStyle)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("demo.done") {
                                    isDialSettingsPresented = false
                                }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    DemoView()
}
