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
    }

    @MainActor
    func testTutorialAvancaAteOFimELevaAoPainel() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting-mostrar-tutorial"]
        app.launch()

        let proximo = app.buttons["Próximo"]
        XCTAssertTrue(proximo.waitForExistence(timeout: 5))
        while proximo.exists { proximo.tap() }
        app.buttons["Começar a usar"].tap()

        XCTAssertTrue(app.tabBars.buttons["Painel"].waitForExistence(timeout: 5))
    }
}
