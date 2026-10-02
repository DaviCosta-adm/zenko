import AuthenticationServices
import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    enum Modo: String, CaseIterable, Identifiable {
        case entrar, criarConta
        var id: String { rawValue }
        var titulo: String { self == .entrar ? "Entrar" : "Criar conta" }
    }

    var modo: Modo = .entrar {
        didSet { erro = nil; aviso = nil }
    }
    var email = ""
    var senha = ""
    var mostrarSenha = false
    private(set) var carregando = false
    var erro: String?
    var aviso: String?

    private var nonceApple: String?

    private var emailLimpo: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Validação local antes de ir ao servidor, com mensagens em linguagem simples.
    func validar() -> String? {
        if emailLimpo.isEmpty { return "Digite seu e-mail." }
        if !emailLimpo.contains("@") || !emailLimpo.contains(".") { return "Esse e-mail não parece válido." }
        if senha.isEmpty { return "Digite sua senha." }
        if modo == .criarConta && senha.count < 6 { return "A senha precisa ter pelo menos 6 caracteres." }
        return nil
    }

    func enviar(auth: AuthController) async {
        erro = nil
        aviso = nil
        if let problema = validar() {
            erro = problema
            return
        }

        carregando = true
        defer { carregando = false }
        do {
            switch modo {
            case .entrar:
                try await auth.entrar(email: emailLimpo, senha: senha)
            case .criarConta:
                if try await auth.cadastrar(email: emailLimpo, senha: senha) {
                    modo = .entrar
                    aviso = "Conta criada! Enviamos um link para \(emailLimpo). Abra o e-mail, toque no link e depois entre aqui."
                }
            }
        } catch {
            erro = mensagem(de: error)
        }
    }

    func esqueciSenha(auth: AuthController) async {
        erro = nil
        aviso = nil
        guard !emailLimpo.isEmpty, emailLimpo.contains("@") else {
            erro = "Digite seu e-mail acima e toque de novo em \"Esqueci minha senha\"."
            return
        }

        carregando = true
        defer { carregando = false }
        do {
            try await auth.recuperarSenha(email: emailLimpo)
            aviso = "Se existir uma conta com \(emailLimpo), você vai receber um link para criar uma nova senha."
        } catch {
            erro = mensagem(de: error)
        }
    }

    func prepararApple(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = NonceApple.gerar()
        nonceApple = nonce
        request.requestedScopes = [.email]
        request.nonce = NonceApple.sha256(nonce)
    }

    func concluirApple(_ resultado: Result<ASAuthorization, Error>, auth: AuthController) async {
        erro = nil
        aviso = nil
        switch resultado {
        case .failure(let falha):
            let codigo = (falha as? ASAuthorizationError)?.code
            if codigo == .canceled { return }
            // `.unknown` é o que chega quando o app não tem a capability Sign in with Apple.
            erro = codigo == .unknown ? ErroAuth.appleIndisponivel.errorDescription : mensagem(de: falha)

        case .success(let autorizacao):
            guard let credencial = autorizacao.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credencial.identityToken,
                  let token = String(data: tokenData, encoding: .utf8),
                  let nonce = nonceApple else {
                erro = ErroAuth.appleIndisponivel.errorDescription
                return
            }
            carregando = true
            defer { carregando = false }
            do {
                try await auth.entrarComApple(idToken: token, nonce: nonce)
            } catch {
                erro = mensagem(de: error)
            }
        }
    }

    private func mensagem(de erro: Error) -> String {
        (erro as? ErroAuth)?.errorDescription ?? erro.localizedDescription
    }
}
