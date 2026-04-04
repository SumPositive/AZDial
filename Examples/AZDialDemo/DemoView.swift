import SwiftUI
import AZDial

struct DemoView: View {
    @State private var selectedStyle: DialStyle = .regacy
    @State private var value1 = 120     // 体重 60.0 kg (×10)
    @State private var value2 = 130     // 収縮期血圧
    @State private var value3 = 170     // 身長 cm
    @State private var value4 = 0       // 0 to 100

    var body: some View {
        NavigationStack {
            List {

                // MARK: - スタイル選択
                Section("ダイアルスタイル") {
                    HStack(spacing: 10) {
                        ForEach(DialStyle.allBuiltin, id: \.id) { style in
                            let selected = selectedStyle.id == style.id
                            Button {
                                selectedStyle = style
                            } label: {
                                VStack(spacing: 6) {
                                    AZDialBack(offset: 5, tickGap: 10, style: style)
                                        .frame(height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    selected ? Color.accentColor : Color.secondary.opacity(0.3),
                                                    lineWidth: selected ? 2.5 : 1
                                                )
                                        )
                                    Text(style.label)
                                        .font(.caption2)
                                        .foregroundStyle(selected ? .primary : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 4)
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
                        style: selectedStyle
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
                        style: selectedStyle
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
                        style: selectedStyle
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
                        style: selectedStyle
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
                                dialWidth: CGFloat(width)
                            )
                        }
                    }
                } header: {
                    Text("dialWidth")
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
        }
    }
}

#Preview {
    DemoView()
}
