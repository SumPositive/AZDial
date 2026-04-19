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
                        Label("ダイアル設定を開く", systemImage: "slider.horizontal.3")
                    }
                    Text("この設定シート表示APIがあります。ユーザアプリから呼び出すことができます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("🎨 クールなスタイルや感度パラメータを提案・提供してください！\nサンプル公開、さらには標準スタイルや感度への採用も検討します。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } header: {
                    Text("ダイアル設定")
                }

                // MARK: - 小数点あり（体重）
                Section {
                    HStack {
                        Text("体重")
                        Spacer()
                        Text(String(format: "%.1f kg", Double(value1) / 10))
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
                    Text("小数点あり・ステッパー表示")
                }

                // MARK: - 整数（血圧）
                Section {
                    HStack {
                        Text("収縮期血圧")
                        Spacer()
                        Text("\(value2) mmHg")
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
                    Text("整数・ステッパー表示")
                }

                // MARK: - ステッパー非表示
                Section {
                    HStack {
                        Text("身長")
                        Spacer()
                        Text("\(value3) cm")
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
                    Text("ステッパー非表示")
                }

                // MARK: - 範囲 0〜100
                Section {
                    HStack {
                        Text("レベル")
                        Spacer()
                        Text("\(value4)")
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
                    Text("0〜100")
                }

                // MARK: - dialWidth
                Section {
                    ForEach([80, 120, 160, 220], id: \.self) { width in
                        HStack {
                            Text("\(width) pt")
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
                    Text("dialWidth")
                }

                // MARK: - ジェスチャー独立性テスト
                Section {
                    Text("ダイアルを横にスワイプしてもScrollViewが動かなければOK")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ZStack {
                        ScrollView(.horizontal, showsIndicators: true) {
                            HStack(spacing: 0) {
                                ForEach(0..<6, id: \.self) { i in
                                    Text("ページ \(i + 1)")
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
                    Text("ジェスチャー独立性テスト")
                }

                // MARK: - 画像タイル（使い方の案内）
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assets.xcassets に画像を登録後：")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("""
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
                    Text("カスタム画像タイル")
                }
            }
            .navigationTitle("AZDial Demo")
            .sheet(isPresented: $isDialSettingsPresented) {
                NavigationStack {
                    AZDialSettingsView(tuning: $interactionTuning, style: $selectedStyle)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("完了") {
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
