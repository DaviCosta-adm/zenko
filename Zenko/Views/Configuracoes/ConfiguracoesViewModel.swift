import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ConfiguracoesViewModel {
    func garantirPreferencias(context: ModelContext) {
        PreferenciaRepository(context: context).carregarOuCriar()
    }

    func adicionarRegra(palavra: String, peso: Int, context: ModelContext) {
        let valor = palavra.trimmingCharacters(in: .whitespaces)
        guard !valor.isEmpty else { return }
        PreferenciaRepository(context: context).adicionarRegra(
            RegraClassificacao(tipo: "palavraChave", valor: valor, pesoAtribuido: peso)
        )
    }

    func removerRegra(_ regra: RegraClassificacao, context: ModelContext) {
        PreferenciaRepository(context: context).removerRegra(regra)
    }

    func reagendarLembretes(context: ModelContext) {
        LembreteRepository(context: context).reagendarTodos()
    }
}
