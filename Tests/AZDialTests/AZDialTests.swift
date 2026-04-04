import XCTest
@testable import AZDial

final class AZDialStyleTests: XCTestCase {

    // MARK: - id

    func testBuiltinIds() {
        XCTAssertEqual(DialStyle.regacy.id,   "regacy")
        XCTAssertEqual(DialStyle.varnia.id,   "varnia")
        XCTAssertEqual(DialStyle.chrome.id,   "chrome")
        XCTAssertEqual(DialStyle.hairline.id, "hairline")
        XCTAssertEqual(DialStyle.rubber.id,   "rubber")
    }

    func testTileIdLightOnly() {
        let style = DialStyle.tile(light: "MyTile")
        XCTAssertEqual(style.id, "tile:MyTile:")
    }

    func testTileIdWithDark() {
        let style = DialStyle.tile(light: "MyTile", dark: "MyTileDark")
        XCTAssertEqual(style.id, "tile:MyTile:MyTileDark")
    }

    // MARK: - label

    func testBuiltinLabels() {
        XCTAssertEqual(DialStyle.regacy.label,   "Regacy")
        XCTAssertEqual(DialStyle.varnia.label,   "Varnia")
        XCTAssertEqual(DialStyle.chrome.label,   "Chrome")
        XCTAssertEqual(DialStyle.hairline.label, "Hairline")
        XCTAssertEqual(DialStyle.rubber.label,   "Rubber")
    }

    func testTileLabelUsesLightName() {
        let style = DialStyle.tile(light: "DialTile_Oval", dark: "DialTile_Oval_Dark")
        XCTAssertEqual(style.label, "DialTile_Oval")
    }

    // MARK: - allBuiltin

    func testAllBuiltinCount() {
        XCTAssertEqual(DialStyle.allBuiltin.count, 5)
    }

    func testAllBuiltinContainsAllCases() {
        let ids = Set(DialStyle.allBuiltin.map(\.id))
        XCTAssertTrue(ids.contains("regacy"))
        XCTAssertTrue(ids.contains("varnia"))
        XCTAssertTrue(ids.contains("chrome"))
        XCTAssertTrue(ids.contains("hairline"))
        XCTAssertTrue(ids.contains("rubber"))
    }

    func testAllBuiltinHasUniqueIds() {
        let ids = DialStyle.allBuiltin.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "allBuiltin must not contain duplicate ids")
    }

    // MARK: - builtin(id:)

    func testBuiltinRoundTrip() {
        for style in DialStyle.allBuiltin {
            let restored = DialStyle.builtin(id: style.id)
            XCTAssertNotNil(restored, "builtin(id:) must restore \(style.id)")
            XCTAssertEqual(restored?.id, style.id)
        }
    }

    func testBuiltinWithUnknownId() {
        XCTAssertNil(DialStyle.builtin(id: "unknown"))
        XCTAssertNil(DialStyle.builtin(id: ""))
    }

    func testBuiltinRejectsRemovedStyles() {
        // These were valid in v1.x but are no longer supported
        XCTAssertNil(DialStyle.builtin(id: "machined"))
        XCTAssertNil(DialStyle.builtin(id: "soft"))
        XCTAssertNil(DialStyle.builtin(id: "fine"))
        XCTAssertNil(DialStyle.builtin(id: "gold"))
        XCTAssertNil(DialStyle.builtin(id: "vintage"))
    }

    func testBuiltinRejectsTileId() {
        XCTAssertNil(DialStyle.builtin(id: "tile:MyTile:"))
    }

    // MARK: - Legacy Int migration (mirrors AppSettings migration logic)

    func testLegacyIntMigration() {
        XCTAssertEqual(migrateOldInt(0), "varnia")   // soft
        XCTAssertEqual(migrateOldInt(1), "varnia")   // machined
        XCTAssertEqual(migrateOldInt(2), "chrome")   // chrome
        XCTAssertEqual(migrateOldInt(3), "varnia")   // fine
        XCTAssertEqual(migrateOldInt(4), "hairline") // hairline
        XCTAssertEqual(migrateOldInt(5), "rubber")   // rubber
        XCTAssertEqual(migrateOldInt(6), "varnia")   // gold
        XCTAssertEqual(migrateOldInt(7), "varnia")   // vintage
    }

    func testLegacyMigratedIdsAreValid() {
        for oldInt in 0...7 {
            let id = migrateOldInt(oldInt)
            XCTAssertNotNil(DialStyle.builtin(id: id),
                            "Migrated id '\(id)' from old int \(oldInt) must be a valid builtin")
        }
    }

    /// Mirrors the migration logic in Condition2's AppSettings.
    private func migrateOldInt(_ oldInt: Int) -> String {
        switch oldInt {
        case 2:  return DialStyle.chrome.id
        case 4:  return DialStyle.hairline.id
        case 5:  return DialStyle.rubber.id
        default: return DialStyle.varnia.id
        }
    }
}
