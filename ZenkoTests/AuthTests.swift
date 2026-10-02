import XCTest
@testable import Zenko

@MainActor
final class AuthTests: XCTestCase {
    private func corpo(_ json: String) -> Data { Data(json.utf8) }

    func testErrosNoFormatoAtualDoSupabase() {
        XCTAssertEqual(ErroAuth.deResposta(status: 400, corpo: corpo(#"{"code":400,"error_code":"invalid_credentials","msg":"Invalid login credentials"}"#)), .credenciaisInvalidas)
        XCTAssertEqual(ErroAuth.deResposta(status: 400, corpo: corpo(#"{"error_code":"email_not_confirmed","msg":"Email not confirmed"}"#)), .emailNaoConfirmado)
        XCTAssertEqual(ErroAuth.deResposta(status: 422, corpo: corpo(#"{"error_code":"user_already_exists","msg":"User already registered"}"#)), .emailJaCadastrado)
        XCTAssertEqual(ErroAuth.deResposta(status: 422, corpo: corpo(#"{"error_code":"weak_password","msg":"Password should be at least 6 characters."}"#)), .senhaFraca)
        XCTAssertEqual(ErroAuth.deResposta(status: 429, corpo: corpo(#"{"error_code":"over_email_send_rate_limit","msg":"..."}"#)), .muitasTentativas)
    }

    func testErrosNoFormatoAntigoEDesconhecidos() {
        XCTAssertEqual(ErroAuth.deResposta(status: 400, corpo: corpo(#"{"error":"invalid_grant","error_description":"Invalid login credentials"}"#)), .credenciaisInvalidas)
        XCTAssertEqual(ErroAuth.deResposta(status: 429, corpo: Data()), .muitasTentativas)
        XCTAssertEqual(ErroAuth.deResposta(status: 500, corpo: Data()), .desconhecido("erro 500"))
    }

    func testDecodificaSessaoDoLogin() throws {
        let agora = Date(timeIntervalSince1970: 1_000_000)
        let json = #"{"access_token":"aaa","token_type":"bearer","expires_in":3600,"refresh_token":"rrr","user":{"id":"u-1","email":"ana@exemplo.com"}}"#

        let sessao = try XCTUnwrap(SupabaseAuthClient.decodificarSessao(corpo(json), agora: agora))

        XCTAssertEqual(sessao.accessToken, "aaa")
        XCTAssertEqual(sessao.refreshToken, "rrr")
        XCTAssertEqual(sessao.usuarioId, "u-1")
        XCTAssertEqual(sessao.email, "ana@exemplo.com")
        XCTAssertEqual(sessao.expiraEm, agora.addingTimeInterval(3600))
    }

    func testCadastroAguardandoConfirmacaoNaoTemSessao() throws {
        let json = #"{"id":"u-2","email":"bia@exemplo.com","confirmation_sent_at":"2026-10-02T12:00:00Z"}"#
        XCTAssertNil(try SupabaseAuthClient.decodificarSessao(corpo(json)))
    }

    func testSemConfiguracaoNaoChamaServidor() async {
        let cliente = SupabaseAuthClient(url: "", chave: "")
        XCTAssertFalse(cliente.configurado)
        do {
            _ = try await cliente.entrar(email: "a@b.com", senha: "123456")
            XCTFail("deveria falhar")
        } catch {
            XCTAssertEqual(error as? ErroAuth, .naoConfigurado)
        }
    }

    func testSha256DoNonce() {
        XCTAssertEqual(NonceApple.sha256("abc"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        XCTAssertEqual(NonceApple.gerar().count, 32)
        XCTAssertNotEqual(NonceApple.gerar(), NonceApple.gerar())
    }

    func testValidacaoLocalDoFormulario() {
        let vm = LoginViewModel()
        XCTAssertEqual(vm.validar(), "Digite seu e-mail.")
        vm.email = "ana"
        XCTAssertEqual(vm.validar(), "Esse e-mail não parece válido.")
        vm.email = " Ana@Exemplo.com "
        XCTAssertEqual(vm.validar(), "Digite sua senha.")
        vm.modo = .criarConta
        vm.senha = "123"
        XCTAssertEqual(vm.validar(), "A senha precisa ter pelo menos 6 caracteres.")
        vm.senha = "123456"
        XCTAssertNil(vm.validar())
    }
}
