import Foundation
import SwiftData

@MainActor
final class PreferenciaRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    /// Na primeira execução cria as preferências padrão e algumas regras iniciais.
    @discardableResult
    func carregarOuCriar() -> PreferenciaUsuario {
        if let existente = try? context.fetch(FetchDescriptor<PreferenciaUsuario>()).first {
            return existente
        }

        let preferencia = PreferenciaUsuario()
        context.insert(preferencia)
        regrasIniciais().forEach(context.insert)
        try? context.save()
        return preferencia
    }

    func regras() -> [RegraClassificacao] {
        (try? context.fetch(FetchDescriptor<RegraClassificacao>())) ?? []
    }

    func adicionarRegra(_ regra: RegraClassificacao) {
        context.insert(regra)
        try? context.save()
    }

    func removerRegra(_ regra: RegraClassificacao) {
        context.delete(regra)
        try? context.save()
    }

    private func regrasIniciais() -> [RegraClassificacao] {
        [
            RegraClassificacao(tipo: "palavraChave", valor: "boleto", pesoAtribuido: 30),
            RegraClassificacao(tipo: "palavraChave", valor: "fatura", pesoAtribuido: 30),
            RegraClassificacao(tipo: "palavraChave", valor: "vence", pesoAtribuido: 20),
            RegraClassificacao(tipo: "palavraChave", valor: "prazo", pesoAtribuido: 20),
            RegraClassificacao(tipo: "palavraChave", valor: "promoção", pesoAtribuido: -30),
        ]
    }
}
