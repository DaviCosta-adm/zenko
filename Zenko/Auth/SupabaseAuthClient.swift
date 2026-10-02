import Foundation

struct SessaoSupabase: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiraEm: Date
    let usuarioId: String
    let email: String?

    /// Margem de 1 minuto para não usar um token que vence no meio de uma requisição.
    var expirada: Bool { expiraEm.timeIntervalSinceNow < 60 }
}

enum ResultadoCadastro: Equatable {
    case logado(SessaoSupabase)
    case confirmarEmail
}

enum ErroAuth: LocalizedError, Equatable {
    case naoConfigurado
    case credenciaisInvalidas
    case emailNaoConfirmado
    case emailJaCadastrado
    case senhaFraca
    case emailInvalido
    case muitasTentativas
    case semConexao
    case appleIndisponivel
    case desconhecido(String)

    var errorDescription: String? {
        switch self {
        case .naoConfigurado: "O servidor de login ainda não foi configurado."
        case .credenciaisInvalidas: "E-mail ou senha incorretos."
        case .emailNaoConfirmado: "Confirme seu e-mail antes de entrar. Procure a mensagem do Zenko na sua caixa de entrada."
        case .emailJaCadastrado: "Já existe uma conta com esse e-mail. Toque em \"Entrar\"."
        case .senhaFraca: "Senha fraca. Use pelo menos 6 caracteres."
        case .emailInvalido: "Esse e-mail não parece válido."
        case .muitasTentativas: "Muitas tentativas seguidas. Espere alguns minutos e tente de novo."
        case .semConexao: "Sem conexão com a internet."
        case .appleIndisponivel: "Entrar com Apple ainda não está ativado neste app. Use e-mail e senha."
        case .desconhecido(let mensagem): "Não foi possível concluir: \(mensagem)"
        }
    }

    /// Supabase Auth responde erros em dois formatos: `{error_code, msg}` (atual) e
    /// `{error, error_description}` (antigo). Os dois são tratados.
    static func deResposta(status: Int, corpo: Data) -> ErroAuth {
        let json = (try? JSONSerialization.jsonObject(with: corpo)) as? [String: Any] ?? [:]
        let codigo = (json["error_code"] as? String) ?? (json["error"] as? String) ?? ""
        let mensagem = (json["msg"] as? String) ?? (json["error_description"] as? String) ?? (json["message"] as? String) ?? ""

        switch codigo {
        case "invalid_credentials": return .credenciaisInvalidas
        case "email_not_confirmed": return .emailNaoConfirmado
        case "user_already_exists", "email_exists": return .emailJaCadastrado
        case "weak_password": return .senhaFraca
        case "email_address_invalid": return .emailInvalido
        case "over_request_rate_limit", "over_email_send_rate_limit": return .muitasTentativas
        default: break
        }

        let minusculas = mensagem.lowercased()
        if minusculas.contains("invalid login credentials") { return .credenciaisInvalidas }
        if minusculas.contains("email not confirmed") { return .emailNaoConfirmado }
        if minusculas.contains("already registered") { return .emailJaCadastrado }
        if minusculas.contains("password should be") { return .senhaFraca }
        if status == 429 { return .muitasTentativas }
        return .desconhecido(mensagem.isEmpty ? "erro \(status)" : mensagem)
    }
}

/// Cliente mínimo da API REST do Supabase Auth (GoTrue), só com o que o login precisa.
final class SupabaseAuthClient {
    private let urlBase: URL?
    private let chave: String
    private let sessao: URLSession

    init(url: String = SupabaseConfig.url, chave: String = SupabaseConfig.chavePublica, sessao: URLSession = .shared) {
        self.urlBase = url.isEmpty ? nil : URL(string: url)
        self.chave = chave
        self.sessao = sessao
    }

    var configurado: Bool { urlBase != nil && !chave.isEmpty }

    func entrar(email: String, senha: String) async throws -> SessaoSupabase {
        let dados = try await enviar("token?grant_type=password", corpo: ["email": email, "password": senha])
        guard let sessao = try Self.decodificarSessao(dados) else { throw ErroAuth.desconhecido("resposta sem sessão") }
        return sessao
    }

    /// Com "Confirm email" ligado no Supabase, o cadastro não devolve sessão: a pessoa
    /// precisa clicar no link do e-mail primeiro.
    func cadastrar(email: String, senha: String) async throws -> ResultadoCadastro {
        let dados = try await enviar("signup", corpo: ["email": email, "password": senha])
        if let sessao = try Self.decodificarSessao(dados) { return .logado(sessao) }
        return .confirmarEmail
    }

    func entrarComApple(idToken: String, nonce: String) async throws -> SessaoSupabase {
        let dados = try await enviar("token?grant_type=id_token", corpo: ["provider": "apple", "id_token": idToken, "nonce": nonce])
        guard let sessao = try Self.decodificarSessao(dados) else { throw ErroAuth.desconhecido("resposta sem sessão") }
        return sessao
    }

    func renovar(refreshToken: String) async throws -> SessaoSupabase {
        let dados = try await enviar("token?grant_type=refresh_token", corpo: ["refresh_token": refreshToken])
        guard let sessao = try Self.decodificarSessao(dados) else { throw ErroAuth.desconhecido("resposta sem sessão") }
        return sessao
    }

    func recuperarSenha(email: String) async throws {
        _ = try await enviar("recover", corpo: ["email": email])
    }

    /// Falhas aqui são ignoradas: a sessão local é apagada de qualquer jeito.
    func sair(accessToken: String) async {
        _ = try? await enviar("logout", corpo: [:], token: accessToken)
    }

    private func enviar(_ caminho: String, corpo: [String: String], token: String? = nil) async throws -> Data {
        guard let urlBase, configurado, let url = URL(string: "auth/v1/\(caminho)", relativeTo: urlBase) else {
            throw ErroAuth.naoConfigurado
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(chave, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token ?? chave)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(corpo)

        let dados: Data
        let resposta: URLResponse
        do {
            (dados, resposta) = try await sessao.data(for: request)
        } catch let erro as URLError where [.notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost].contains(erro.code) {
            throw ErroAuth.semConexao
        }

        let status = (resposta as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw ErroAuth.deResposta(status: status, corpo: dados) }
        return dados
    }

    /// Devolve nil quando a resposta é válida mas não traz sessão (cadastro aguardando confirmação).
    static func decodificarSessao(_ dados: Data, agora: Date = .now) throws -> SessaoSupabase? {
        let resposta = try JSONDecoder().decode(RespostaToken.self, from: dados)
        guard let accessToken = resposta.access_token,
              let refreshToken = resposta.refresh_token,
              let usuario = resposta.user else { return nil }
        return SessaoSupabase(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiraEm: agora.addingTimeInterval(TimeInterval(resposta.expires_in ?? 3600)),
            usuarioId: usuario.id,
            email: usuario.email
        )
    }
}

private struct RespostaToken: Decodable {
    struct Usuario: Decodable {
        let id: String
        let email: String?
    }

    let access_token: String?
    let refresh_token: String?
    let expires_in: Int?
    let user: Usuario?
}
