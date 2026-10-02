import XCTest

final class ZenkoUITests: XCTestCase {
    @MainActor
    func testAbreComAsTresAbas() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting-pular-tutorial"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Painel"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Lembretes"].exists)
        XCTAssertTrue(app.tabBars.buttons["Configurações"].exists)
        XCTAssertFalse(app.buttons["Próximo"].exists)
    }

    @MainActor
    func testTourPercorreTodasAsAbasEFecha() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting-mostrar-tutorial"]
        app.launch()

        let proximo = app.buttons["Próximo"]
        XCTAssertTrue(proximo.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bem-vindo ao Zenko"].exists)

        while proximo.exists { proximo.tap() }

        XCTAssertTrue(app.staticTexts["Pronto!"].exists)
        app.buttons["Concluir"].tap()

        XCTAssertFalse(app.buttons["Concluir"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.navigationBars["Zenko"].exists)
    }

    @MainActor
    func testPularEncerraOTour() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting-mostrar-tutorial"]
        app.launch()

        XCTAssertTrue(app.buttons["Pular"].waitForExistence(timeout: 5))
        app.buttons["Pular"].tap()

        XCTAssertFalse(app.buttons["Próximo"].waitForExistence(timeout: 1))
    }
}
