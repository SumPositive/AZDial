import XCTest
@testable import AZDial

// MARK: - DialStyle

final class AZDialStyleTests: XCTestCase {

    /// 画像タイル方式の組み込みスタイル（`generatedTileWidth` が nil になる）。
    private let imageStyleIDs: Set<String> = ["regacy", "midnight", "brass", "ocean", "shape"]
    /// CoreGraphics 生成方式の組み込みスタイル。
    private let generatedStyleIDs: Set<String> =
        ["varnia", "chrome", "hairline", "rubber", "rhombus", "braid", "cobble"]

    // MARK: id / label

    func testIdLabelRoundTripForAllBuiltins() {
        for style in DialStyle.allBuiltin {
            // id は空でない一意な文字列で、builtin(id:) で必ず復元できる。
            XCTAssertFalse(style.id.isEmpty, "id must not be empty")
            XCTAssertFalse(style.label.isEmpty, "label must not be empty")
            XCTAssertEqual(DialStyle.builtin(id: style.id)?.id, style.id,
                           "builtin(id:) must restore \(style.id)")
        }
    }

    func testAllBuiltinHasUniqueIds() {
        let ids = DialStyle.allBuiltin.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "allBuiltin must not contain duplicate ids")
    }

    func testAllBuiltinCoversKnownStyles() {
        let ids = Set(DialStyle.allBuiltin.map(\.id))
        XCTAssertEqual(ids, imageStyleIDs.union(generatedStyleIDs),
                       "allBuiltin の構成が想定と異なる（スタイルの追加/削除時はここを更新）")
    }

    // MARK: builtin(id:)

    func testBuiltinWithUnknownIdReturnsNil() {
        XCTAssertNil(DialStyle.builtin(id: "unknown"))
        XCTAssertNil(DialStyle.builtin(id: ""))
    }

    func testBuiltinRejectsTileAndDrawnIds() {
        // .tile / .drawn はクロージャ/外部資産を伴うため id からは復元できない。
        XCTAssertNil(DialStyle.builtin(id: "tile:MyTile:"))
        XCTAssertNil(DialStyle.builtin(id: "drawn:myStyle"))
    }

    func testBuiltinRejectsRenamedAndRemovedIds() {
        // 旧名・中間名で永続化された値が誤って復元されないことを保証する。
        for stale in ["machined", "soft", "gold", "vintage",     // v1.x
                      "copper", "diamond", "carbon",             // 中間名
                      "tread", "rain", "rainFine"] {             // 中間名
            XCTAssertNil(DialStyle.builtin(id: stale),
                         "renamed/removed id '\(stale)' must not resolve")
        }
    }

    // MARK: generatedTileWidth

    func testImageStylesHaveNoGeneratedTileWidth() {
        for style in DialStyle.allBuiltin where imageStyleIDs.contains(style.id) {
            XCTAssertNil(style.generatedTileWidth, "\(style.id) は画像方式なので nil のはず")
        }
        XCTAssertNil(DialStyle.tile(light: "X").generatedTileWidth)
    }

    func testGeneratedStylesHavePositiveTileWidth() {
        for style in DialStyle.allBuiltin where generatedStyleIDs.contains(style.id) {
            let width = style.generatedTileWidth
            XCTAssertNotNil(width, "\(style.id) は生成方式なので幅を持つはず")
            XCTAssertGreaterThan(width ?? 0, 0, "\(style.id) の幅は正でなければならない")
        }
    }

    // MARK: .drawn (custom CoreGraphics)

    func testDrawnIdAndLabel() {
        let style = DialStyle.drawn(id: "myStyle", tileWidth: 30) { _, _, _ in }
        XCTAssertEqual(style.id, "drawn:myStyle")
        XCTAssertEqual(style.label, "myStyle")
    }

    func testDrawnTileWidthIsClampedPositive() {
        XCTAssertEqual(DialStyle.drawn(id: "a", tileWidth: 30) { _, _, _ in }.generatedTileWidth, 30)
        XCTAssertEqual(DialStyle.drawn(id: "b", tileWidth: 0) { _, _, _ in }.generatedTileWidth, 1,
                       "tileWidth は 1 以上にクランプされる")
    }

    // MARK: .tile

    func testTileId() {
        XCTAssertEqual(DialStyle.tile(light: "MyTile").id, "tile:MyTile:")
        XCTAssertEqual(DialStyle.tile(light: "MyTile", dark: "MyTileDark").id, "tile:MyTile:MyTileDark")
    }

    func testTileLabelUsesLightName() {
        XCTAssertEqual(DialStyle.tile(light: "DialTile_Oval", dark: "DialTile_Oval_Dark").label,
                       "DialTile_Oval")
    }

    // MARK: Legacy Int migration (mirrors AppSettings migration logic)

    func testLegacyMigratedIdsAreValid() {
        for oldInt in 0...7 {
            let id = migrateOldInt(oldInt)
            XCTAssertNotNil(DialStyle.builtin(id: id),
                            "Migrated id '\(id)' from old int \(oldInt) must be a valid builtin")
        }
    }

    private func migrateOldInt(_ oldInt: Int) -> String {
        switch oldInt {
        case 2:  return DialStyle.chrome.id
        case 4:  return DialStyle.hairline.id
        case 5:  return DialStyle.rubber.id
        default: return DialStyle.varnia.id
        }
    }
}

// MARK: - AZDialInteractionTuning

final class AZDialInteractionTuningTests: XCTestCase {

    func testInitClampsValuesIntoValidRange() {
        let low = AZDialInteractionTuning(
            pitch: 1,                    // < 5
            velocitySmoothing: -0.5,     // < 0
            inertiaStartVelocity: -10,   // < 0
            fastSwipeVelocity: -10,      // < 0
            slowSwipeMultiplier: 0,      // < 1
            fastSwipeMultiplier: 0,      // < 1
            inertiaDecay: 0.5,           // < 0.80
            inertiaStopVelocity: 0       // < 1
        )
        XCTAssertEqual(low.pitch, 5)
        XCTAssertEqual(low.velocitySmoothing, 0)
        XCTAssertEqual(low.inertiaStartVelocity, 0)
        XCTAssertEqual(low.fastSwipeVelocity, 0)
        XCTAssertEqual(low.slowSwipeMultiplier, 1)
        XCTAssertEqual(low.fastSwipeMultiplier, 1)
        XCTAssertEqual(low.inertiaDecay, 0.80, accuracy: 0.0001)
        XCTAssertEqual(low.inertiaStopVelocity, 1)

        let high = AZDialInteractionTuning(velocitySmoothing: 2.0, inertiaDecay: 0.999)
        XCTAssertEqual(high.velocitySmoothing, 1)
        XCTAssertEqual(high.inertiaDecay, 0.99, accuracy: 0.0001)
    }

    func testDefaultEqualsMildPreset() {
        // 設定：操作感度のデフォルトは「控えめ（mild）」。
        XCTAssertEqual(AZDialInteractionTuning.default,
                       AZDialInteractionTuningPreset.mild.tuning)
    }

    func testDefaultDiffersFromStandardPreset() {
        XCTAssertNotEqual(AZDialInteractionTuning.default,
                          AZDialInteractionTuningPreset.standard.tuning)
    }

    func testCodableRoundTrip() throws {
        let original = AZDialInteractionTuning.default
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AZDialInteractionTuning.self, from: data)
        XCTAssertEqual(original, decoded, "Codable で往復しても等価でなければならない")
    }
}

// MARK: - Presets

final class AZDialPresetTests: XCTestCase {

    func testAllPresetsCountAndUniqueIds() {
        XCTAssertEqual(AZDialInteractionTuningPreset.all.count, 5)
        let ids = AZDialInteractionTuningPreset.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "preset id は一意でなければならない")
    }

    func testStandardPresetPitch() {
        XCTAssertEqual(AZDialInteractionTuningPreset.standard.tuning.pitch, 20)
    }

    func testPresetTitlesAreNonEmpty() {
        for preset in AZDialInteractionTuningPreset.all {
            XCTAssertFalse(preset.title.isEmpty)
        }
    }
}

// MARK: - AZDialSettingsConfiguration

final class AZDialSettingsConfigurationTests: XCTestCase {

    func testDefaultStyleColumnMinWidth() {
        XCTAssertEqual(AZDialSettingsConfiguration().styleColumnMinWidth, 80)
    }

    func testStyleColumnMinWidthIsClampedToFloor() {
        XCTAssertEqual(AZDialSettingsConfiguration(styleColumnMinWidth: 10).styleColumnMinWidth, 44)
        XCTAssertEqual(AZDialSettingsConfiguration(styleColumnMinWidth: 150).styleColumnMinWidth, 150)
    }

    func testDefaultStyleCandidatesMatchAllBuiltin() {
        let candidateIDs = AZDialSettingsConfiguration().styleCandidates.map(\.id)
        XCTAssertEqual(candidateIDs, DialStyle.allBuiltin.map(\.id))
    }
}
