import XCTest

final class ZenkoUITests: XCTestCase {
    @MainActor
    func testAbreComAsTresAbas() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Painel"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Lembretes"].exists)
        XCTAssertTrue(app.tabBars.buttons["Configurações"].exists)
    }
}
