import Foundation

enum ErroClassificador: Error, Equatable {
    case naoConfigurado
    case respostaInvalida
}

/// Chama a Edge Function `classificar` no Supabase. A Claude fica só no servidor.
/// Sem endpoint, sem chave ou sem sessão, a classificação usa as regras locais.
final class ClassificadorAPI {
    private let endpoint: URL?
    private let chave: String
    private let sessao: URLSession
    private let tokenDeAcesso: () -> String?

    init(
        endpoint: URL? = nil,
        chave: String? = nil,
        sessao: URLSession = .shared,
        tokenDeAcesso: (() -> String?)? = nil
    ) {
        self.endpoint = endpoint ?? SupabaseConfig.urlClassificador
        self.chave = chave ?? SupabaseConfig.chavePublica
        self.sessao = sessao
        self.tokenDeAcesso = tokenDeAcesso ?? { nil }
    }

    func classificarComIA(titulo: String, conteudo: String, origem: String) async throws -> ResultadoClassificacao {
        let dados = try await enviar(titulo: titulo, conteudo: conteudo, origem: origem)
        if let direto = try? JSONDecoder().decode(RespostaClassificacao.self, from: dados) {
            return normalizar(direto)
        }
        guard let texto = String(data: dados, encoding: .utf8) else { throw ErroClassificador.respostaInvalida }
        return try parseResultado(texto)
    }

    private func enviar(titulo: String, conteudo: String, origem: String) async throws -> Data {
        guard let endpoint, !chave.isEmpty else { throw ErroClassificador.naoConfigurado }
        guard let token = tokenDeAcesso(), !token.isEmpty else { throw ErroClassificador.naoConfigurado }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(chave, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(PedidoClassificacao(
            titulo: titulo,
            conteudo: conteudo,
            origem: origem
        ))

        let (data, resposta) = try await sessao.data(for: request)
        guard let http = resposta as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ErroClassificador.respostaInvalida
        }
        return data
    }

    func parseResultado(_ json: String) throws -> ResultadoClassificacao {
        let limpo = json
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = limpo.data(using: .utf8) else { throw ErroClassificador.respostaInvalida }
        return normalizar(try JSONDecoder().decode(RespostaClassificacao.self, from: data))
    }

    private func normalizar(_ resposta: RespostaClassificacao) -> ResultadoClassificacao {
        let permitidas = ["financeiro", "trabalho", "pessoal", "outro"]
        let categoria = permitidas.contains(resposta.categoria.lowercased())
            ? resposta.categoria.lowercased()
            : "outro"
        return ResultadoClassificacao(
            pontuacao: min(max(resposta.pontuacao, 0), 100),
            categoria: categoria
        )
    }
}

private struct PedidoClassificacao: Encodable {
    let titulo: String
    let conteudo: String
    let origem: String
}

private struct RespostaClassificacao: Decodable {
    let pontuacao: Int
    let categoria: String
}
