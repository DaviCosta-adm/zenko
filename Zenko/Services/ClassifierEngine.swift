import Foundation

struct ResultadoClassificacao: Equatable {
    let pontuacao: Int
    let categoria: String
}

final class ClassifierEngine {
    private let classificadorAPI: ClassificadorAPI

    init(classificadorAPI: ClassificadorAPI? = nil) {
        self.classificadorAPI = classificadorAPI ?? ClassificadorAPI()
    }

    func classificar(
        titulo: String,
        conteudo: String,
        origem: String,
        regras: [RegraClassificacao],
        preferencias: PreferenciaUsuario
    ) async -> ResultadoClassificacao {

        // 1) regras locais
        var pontuacaoBase = 50
        for regra in regras {
            let bateu = regra.tipo == "origem"
                ? origem.localizedCaseInsensitiveContains(regra.valor)
                : (conteudo.localizedCaseInsensitiveContains(regra.valor) ||
                   titulo.localizedCaseInsensitiveContains(regra.valor))
            if bateu { pontuacaoBase += regra.pesoAtribuido }
        }
        pontuacaoBase = min(max(pontuacaoBase, 0), 100)

        let categoriaLocal = categorizarPorPalavras("\(titulo) \(conteudo)")

        // 2) só chama IA se estiver na zona ambígua
        let zonaAmbigua = (preferencias.sensibilidadeIA - 15)...(preferencias.sensibilidadeIA + 15)
        guard zonaAmbigua.contains(pontuacaoBase) else {
            return ResultadoClassificacao(pontuacao: pontuacaoBase, categoria: categoriaLocal)
        }

        do {
            return try await classificadorAPI.classificarComIA(titulo: titulo, conteudo: conteudo, origem: origem)
        } catch {
            return ResultadoClassificacao(pontuacao: pontuacaoBase, categoria: categoriaLocal)
        }
    }

    func categorizarPorPalavras(_ texto: String) -> String {
        if texto.range(of: "pix|boleto|fatura|cartão", options: [.regularExpression, .caseInsensitive]) != nil {
            return "financeiro"
        } else if texto.range(of: "reunião|prazo|entrega|projeto", options: [.regularExpression, .caseInsensitive]) != nil {
            return "trabalho"
        }
        return "pessoal"
    }
}
