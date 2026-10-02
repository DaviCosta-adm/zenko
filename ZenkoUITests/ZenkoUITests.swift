import XCTest

final class ZenkoUITests: XCTestCase {
    @MainActor
    func testAbreComAsTresAbas() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting-sem-login", "-uitesting-pular-tutorial"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Painel"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Lembretes"].exists)
        XCTAssertTrue(app.tabBars.buttons["Configurações"].exists)
        XCTAssertFalse(app.buttons["Próximo"].exists)
    }

    @MainActor
    func testTourPercorreTodasAsAbasEFecha() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting-sem-login", "-uitesting-mostrar-tutorial"]
        app.launch()

        let proximo = app.buttons["Próximo"]
        XCTAssertTrue(proximo.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bem-vindo ao Zenko"].exists)

        let seta = app.images["setaDoTour"]
        for passo in 1...6 {
            XCTAssertTrue(proximo.waitForExistence(timeout: 3))
            XCTAssertTrue(seta.waitForExistence(timeout: 3), "Passo \(passo) sem seta apontando para um elemento")
            proximo.tap()
        }

        XCTAssertTrue(app.buttons["Concluir"].waitForExistence(timeout: 3))
        XCTAssertTrue(seta.waitForExistence(timeout: 3), "Passo 7 sem seta apontando para um elemento")
        XCTAssertTrue(app.staticTexts["Pronto!"].exists)
        app.buttons["Concluir"].tap()

        XCTAssertFalse(app.buttons["Concluir"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.navigationBars["Zenko"].exists)
    }

    @MainActor
    func testPularEncerraOTour() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting-sem-login", "-uitesting-mostrar-tutorial"]
        app.launch()

        XCTAssertTrue(app.buttons["Pular"].waitForExistence(timeout: 5))
        app.buttons["Pular"].tap()

        XCTAssertFalse(app.buttons["Próximo"].waitForExistence(timeout: 1))
    }

    @MainActor
    func testSemLoginAbreATelaDeEntrarEValidaCampos() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting-deslogar"]
        app.launch()

        let enviar = app.buttons["botaoEnviar"]
        XCTAssertTrue(enviar.waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.buttons["Painel"].exists, "O app não pode abrir sem login")

        enviar.tap()
        XCTAssertTrue(app.staticTexts["Digite seu e-mail."].waitForExistence(timeout: 2))

        app.textFields["campoEmail"].tap()
        app.textFields["campoEmail"].typeText("ana@exemplo.com")
        app.buttons["Criar conta"].tap()
        app.secureTextFields["campoSenha"].tap()
        app.secureTextFields["campoSenha"].typeText("123")
        enviar.tap()
        XCTAssertTrue(app.staticTexts["A senha precisa ter pelo menos 6 caracteres."].waitForExistence(timeout: 2))
    }

    /// Usa o servidor real: precisa de internet.
    @MainActor
    func testSenhaErradaMostraMensagemDoServidor() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting-deslogar"]
        app.launch()

        let email = app.textFields["campoEmail"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("naoexiste@zenko.app")
        app.secureTextFields["campoSenha"].tap()
        app.secureTextFields["campoSenha"].typeText("senhaerrada123")
        app.buttons["botaoEnviar"].tap()

        XCTAssertTrue(app.staticTexts["E-mail ou senha incorretos."].waitForExistence(timeout: 15))
        XCTAssertFalse(app.tabBars.buttons["Painel"].exists)
    }

    @MainActor
    func testSairDaContaVoltaParaOLogin() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting-sem-login", "-uitesting-pular-tutorial"]
        app.launch()

        let abaConfiguracoes = app.tabBars.buttons["Configurações"].firstMatch
        XCTAssertTrue(abaConfiguracoes.waitForExistence(timeout: 5))
        abaConfiguracoes.tap()
        let sair = app.buttons["Sair da conta"]
        XCTAssertTrue(sair.waitForExistence(timeout: 3))
        sair.tap()
        app.buttons["Sair"].tap()

        XCTAssertTrue(app.buttons["botaoEnviar"].waitForExistence(timeout: 3))
    }
}
