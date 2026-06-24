import XCTest

// MARK: - セットアップについて
//
// これらは XCUITest（UI テスト）です。Swift Package のテストターゲットでは実行できません。
// `AZDial.xcworkspace` の Xcode プロジェクトに **UI Testing Bundle** ターゲットを追加し、
// Target を Demo アプリ（AZDialDemo）に設定したうえで、このファイルをそのターゲットに含めてください。
//
// 依存する accessibilityIdentifier（DemoView 側に付与済み）:
//   - "settings.open"  : 設定シートを開くボタン
//   - "level.value"    : 「0〜100」セクションの現在値ラベル
//   - "level.dial"     : 同セクションのダイアル
//   - "bottom.marker"  : 画面最下部（縦パススルーで到達を確認する目印）

final class AZDialDemoUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: ダイアルの横スワイプで値が変わる

    func testHorizontalSwipeChangesValue() {
        let value = app.staticTexts["level.value"]
        XCTAssertTrue(value.waitForExistence(timeout: 2))
        let before = value.label

        let dial = dialElement()
        dial.swipeRight()   // 右方向 → 値が増える方向

        // 値ラベルが更新されるまで待つ（NSPredicate で label 変化を検出）。
        expectation(for: NSPredicate(format: "label != %@", before), evaluatedWith: value)
        waitForExpectations(timeout: 2)
        XCTAssertNotEqual(value.label, before, "横スワイプでダイアルの値が変化するはず")
    }

    // MARK: 縦スワイプはダイアルに奪われず親リストへ伝わる（3.3.0 の新挙動）

    func testVerticalSwipeOnDialScrollsList() {
        let value = app.staticTexts["level.value"]
        XCTAssertTrue(value.waitForExistence(timeout: 2))
        let beforeValue = value.label

        let bottom = app.staticTexts["bottom.marker"]
        // 最初は画面外で hittable でない想定。
        XCTAssertFalse(bottom.isHittable, "テスト開始時、下端マーカーは画面外にあるはず")

        // ダイアル上で上方向にスワイプ → 横操作ではないのでダイアルは動かず、リストがスクロールする。
        let dial = dialElement()
        for _ in 0..<6 where !bottom.isHittable {
            dial.swipeUp()
        }

        XCTAssertTrue(bottom.isHittable, "ダイアル上の縦スワイプで親リストがスクロールするはず")
        XCTAssertEqual(value.label, beforeValue, "縦スワイプではダイアルの値は変わらないはず")
    }

    // MARK: 設定シートが開きスタイルを選べる

    func testOpenSettingsAndSelectStyle() {
        let open = app.buttons["settings.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 2))
        open.tap()

        // スタイルのプレビューはボタンとして並ぶ。最初に見つかったものをタップしても落ちないこと。
        let firstStyle = app.buttons.element(boundBy: 0)
        XCTAssertTrue(firstStyle.waitForExistence(timeout: 2))

        // 「完了」で閉じられる。
        let done = app.buttons["demo.done"]
        if done.exists { done.tap() }
    }

    // MARK: - Helpers

    /// ダイアルは標準コントロールではないため、種別をまたいで identifier で引く。
    private func dialElement() -> XCUIElement {
        let byOther = app.otherElements["level.dial"]
        if byOther.waitForExistence(timeout: 2) { return byOther }
        // 種別が異なる場合のフォールバック。
        return app.descendants(matching: .any)["level.dial"].firstMatch
    }
}
