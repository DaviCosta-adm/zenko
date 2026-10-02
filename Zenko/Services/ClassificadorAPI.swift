import Foundation

enum ErroClassificador: Error {
    case naoConfigurado
    case respostaInvalida
}

/// A chave da API Claude não deve ficar dentro do app (qualquer um extrai do binário).
/// `endpoint` deve apontar para um backend próprio (ex: Supabase Edge Function) que recebe
/// `{"prompt": "..."}`, chama a Claude e devolve o texto da resposta.
/// Sem endpoint, a classificação usa só as regras locais.
final class ClassificadorAPI {
    private let endpoint: URL?
    private let sessao: URLSession

    init(endpoint: URL? = nil, sessao: URLSession = .shared) {
        self.endpoint = endpoint
        self.sessao = sessao
    }

    func classificarComIA(titulo: String, conteudo: String, origem: String) async throws -> ResultadoClassificacao {
        let prompt = """
        Classifique o item abaixo em JSON puro, sem texto extra:
        {"pontuacao": 0-100, "categoria": "financeiro|trabalho|pessoal|outro"}

        Origem: \(origem)
        Título: \(titulo)
        Conteúdo: \(conteudo)
        """

        let respostaJSON = try await enviarParaClaude(prompt: prompt)
        return try parseResultado(respostaJSON)
    }

    private func enviarParaClaude(prompt: String) async throws -> String {
        guard let endpoint else { throw ErroClassificador.naoConfigurado }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["prompt": prompt])

        let (data, resposta) = try await sessao.data(for: request)
        guard let http = resposta as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let texto = String(data: data, encoding: .utf8) else {
            throw ErroClassificador.respostaInvalida
        }
        return texto
    }

    func parseResultado(_ json: String) throws -> ResultadoClassificacao {
        let limpo = json
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = limpo.data(using: .utf8) else { throw ErroClassificador.respostaInvalida }
        let resposta = try JSONDecoder().decode(RespostaClassificacao.self, from: data)
        return ResultadoClassificacao(
            pontuacao: min(max(resposta.pontuacao, 0), 100),
            categoria: resposta.categoria
        )
    }
}

private struct RespostaClassificacao: Decodable {
    let pontuacao: Int
    let categoria: String
}
