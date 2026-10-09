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

    func testParseNormalizaCategoriaDesconhecida() throws {
        let resultado = try ClassificadorAPI().parseResultado(#"{"pontuacao": 40, "categoria": "URGENTE"}"#)
        XCTAssertEqual(resultado, ResultadoClassificacao(pontuacao: 40, categoria: "outro"))
    }

    func testEnviaTituloETokenParaAFuncao() async throws {
        ProtocoloClassificador.reiniciar()
        ProtocoloClassificador.dados = Data(#"{"pontuacao":72,"categoria":"financeiro"}"#.utf8)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ProtocoloClassificador.self]
        let api = ClassificadorAPI(
            endpoint: URL(string: "https://exemplo.invalid/functions/v1/classificar")!,
            chave: "chave-publica",
            sessao: URLSession(configuration: config),
            tokenDeAcesso: { "jwt-do-usuario" }
        )

        let resultado = try await api.classificarComIA(titulo: "Boleto", conteudo: "Vence amanhã", origem: "manual")

        XCTAssertEqual(resultado, ResultadoClassificacao(pontuacao: 72, categoria: "financeiro"))
        XCTAssertEqual(ProtocoloClassificador.ultima?.value(forHTTPHeaderField: "apikey"), "chave-publica")
        XCTAssertEqual(ProtocoloClassificador.ultima?.value(forHTTPHeaderField: "Authorization"), "Bearer jwt-do-usuario")
        let corpo = try XCTUnwrap(ProtocoloClassificador.corpo)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: corpo) as? [String: String])
        XCTAssertEqual(json["titulo"], "Boleto")
        XCTAssertEqual(json["conteudo"], "Vence amanhã")
        XCTAssertEqual(json["origem"], "manual")
        XCTAssertNil(json["prompt"], "o prompt fica no servidor, não no iPhone")
    }

    func testSemSessaoNaoChamaServidor() async {
        let api = ClassificadorAPI(
            endpoint: URL(string: "https://exemplo.invalid/classificar")!,
            chave: "chave",
            tokenDeAcesso: { nil }
        )
        do {
            _ = try await api.classificarComIA(titulo: "Pix", conteudo: "R$ 10", origem: "manual")
            XCTFail("deveria falhar sem sessão")
        } catch {
            XCTAssertEqual(error as? ErroClassificador, .naoConfigurado)
        }
    }
}

private final class ProtocoloClassificador: URLProtocol, @unchecked Sendable {
    static var ultima: URLRequest?
    static var corpo: Data?
    static var dados = Data()

    static func reiniciar() {
        ultima = nil
        corpo = nil
        dados = Data()
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.ultima = request
        Self.corpo = request.httpBody ?? Self.ler(request.httpBodyStream)
        let resposta = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: resposta, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.dados)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func ler(_ stream: InputStream?) -> Data? {
        guard let stream else { return nil }
        stream.open()
        defer { stream.close() }
        var dados = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let lidos = stream.read(&buffer, maxLength: buffer.count)
            if lidos <= 0 { break }
            dados.append(buffer, count: lidos)
        }
        return dados
    }
}
