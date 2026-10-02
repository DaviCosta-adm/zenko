import XCTest
@testable import Zenko

@MainActor
final class ClassifierEngineTests: XCTestCase {
    private let motor = ClassifierEngine(classificadorAPI: ClassificadorAPI(endpoint: nil))
    private let preferencias = PreferenciaUsuario(sensibilidadeIA: 50)

    func testRegraForteSaiDaZonaAmbiguaEClassificaComoFinanceiro() async {
        let regras = [RegraClassificacao(tipo: "palavraChave", valor: "boleto", pesoAtribuido: 30)]

        let resultado = await motor.classificar(
            titulo: "Boleto da luz",
            conteudo: "Vence amanhã",
            origem: "manual",
            regras: regras,
            preferencias: preferencias
        )

        XCTAssertEqual(resultado, ResultadoClassificacao(pontuacao: 80, categoria: "financeiro"))
    }

    func testZonaAmbiguaSemIAConfiguradaUsaRegrasLocais() async {
        let resultado = await motor.classificar(
            titulo: "Reunião de projeto",
            conteudo: "Sala 3",
            origem: "calendario",
            regras: [],
            preferencias: preferencias
        )

        XCTAssertEqual(resultado, ResultadoClassificacao(pontuacao: 50, categoria: "trabalho"))
    }

    func testPontuacaoFicaEntreZeroECem() async {
        let regras = [
            RegraClassificacao(tipo: "palavraChave", valor: "promoção", pesoAtribuido: -50),
            RegraClassificacao(tipo: "origem", valor: "manual", pesoAtribuido: -50),
        ]

        let resultado = await motor.classificar(
            titulo: "Promoção imperdível",
            conteudo: "",
            origem: "manual",
            regras: regras,
            preferencias: preferencias
        )

        XCTAssertEqual(resultado.pontuacao, 0)
    }

    func testParseDaRespostaDaIAAceitaBlocoMarkdown() throws {
        let resposta = """
        ```json
        {"pontuacao": 130, "categoria": "trabalho"}
        ```
        """

        let resultado = try ClassificadorAPI().parseResultado(resposta)

        XCTAssertEqual(resultado, ResultadoClassificacao(pontuacao: 100, categoria: "trabalho"))
    }
}
