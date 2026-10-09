import CryptoKit
import Foundation
import Observation
import Security

@MainActor
@Observable
final class AuthController {
    enum Estado: Equatable {
        case carregando
        case deslogado
        case logado(SessaoSupabase)
    }

    private(set) var estado: Estado = .carregando

    private let cliente: SupabaseAuthClient

    init(cliente: SupabaseAuthClient? = nil) {
        self.cliente = cliente ?? SupabaseAuthClient()
    }

    var configurado: Bool { cliente.configurado }

    var email: String? {
        if case .logado(let sessao) = estado { return sessao.email }
        return nil
    }

    /// Token real da sessão. Vazio no modo desenvolvimento, então a IA não é chamada.
    var accessToken: String? {
        guard case .logado(let sessao) = estado, !sessao.accessToken.isEmpty else { return nil }
        return sessao.accessToken
    }

    /// Recupera a sessão do Keychain ao abrir o app e renova o token se ele venceu.
    func restaurar() async {
        #if DEBUG
        let argumentos = ProcessInfo.processInfo.arguments
        if argumentos.contains("-uitesting-deslogar") {
            KeychainSessao.apagar()
        }
        if argumentos.contains("-uitesting-sem-login") || argumentos.contains("-tour-passo") {
            entrarModoDesenvolvimento()
            return
        }
        #endif

        guard let salva = KeychainSessao.carregar() else {
            estado = .deslogado
            return
        }
        guard salva.expirada else {
            estado = .logado(salva)
            return
        }
        do {
            guardar(try await cliente.renovar(refreshToken: salva.refreshToken))
        } catch ErroAuth.semConexao {
            // Sem internet: mantém a pessoa dentro do app; renova na próxima abertura.
            estado = .logado(salva)
        } catch {
            KeychainSessao.apagar()
            estado = .deslogado
        }
    }

    func entrar(email: String, senha: String) async throws {
        guardar(try await cliente.entrar(email: email, senha: senha))
    }

    /// Devolve `true` quando a conta foi criada mas precisa de confirmação por e-mail.
    func cadastrar(email: String, senha: String) async throws -> Bool {
        switch try await cliente.cadastrar(email: email, senha: senha) {
        case .logado(let sessao):
            guardar(sessao)
            return false
        case .confirmarEmail:
            return true
        }
    }

    func entrarComApple(idToken: String, nonce: String) async throws {
        guardar(try await cliente.entrarComApple(idToken: idToken, nonce: nonce))
    }

    func recuperarSenha(email: String) async throws {
        try await cliente.recuperarSenha(email: email)
    }

    func sair() async {
        if case .logado(let sessao) = estado, sessao.usuarioId != Self.idDesenvolvimento {
            await cliente.sair(accessToken: sessao.accessToken)
        }
        KeychainSessao.apagar()
        estado = .deslogado
    }

    #if DEBUG
    /// Só existe em builds de desenvolvimento: entra sem servidor e sem salvar nada no Keychain.
    func entrarModoDesenvolvimento() {
        estado = .logado(SessaoSupabase(
            accessToken: "",
            refreshToken: "",
            expiraEm: .distantFuture,
            usuarioId: Self.idDesenvolvimento,
            email: "desenvolvimento@zenko.app"
        ))
    }
    #endif

    private static let idDesenvolvimento = "desenvolvimento"

    private func guardar(_ sessao: SessaoSupabase) {
        KeychainSessao.salvar(sessao)
        estado = .logado(sessao)
    }
}

/// Nonce do Sign in with Apple: a Apple recebe o hash, o Supabase recebe o valor original
/// e confere que os dois batem (impede reaproveitar um token roubado).
enum NonceApple {
    static func gerar(tamanho: Int = 32) -> String {
        let caracteres = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: tamanho)
        _ = SecRandomCopyBytes(kSecRandomDefault, tamanho, &bytes)
        return String(bytes.map { caracteres[Int($0) % caracteres.count] })
    }

    static func sha256(_ texto: String) -> String {
        SHA256.hash(data: Data(texto.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
