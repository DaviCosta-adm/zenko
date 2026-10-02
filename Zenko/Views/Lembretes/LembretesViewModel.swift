import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class LembretesViewModel {
    var permissaoNegada = false

    private let scheduler: ReminderScheduler

    init(scheduler: ReminderScheduler? = nil) {
        self.scheduler = scheduler ?? ReminderScheduler()
    }

    func verificarPermissao() async {
        permissaoNegada = await scheduler.permissaoFoiNegada()
    }

    /// A permissão só é pedida aqui, no primeiro lembrete, e não ao abrir a aba.
    func criar(titulo: String, descricao: String, hora: Int, minuto: Int, diasSemana: Set<Int>, context: ModelContext) async {
        permissaoNegada = !(await scheduler.solicitarPermissao())
        let lembrete = Lembrete(
            titulo: titulo,
            descricao: descricao.isEmpty ? nil : descricao,
            hora: hora,
            minuto: minuto,
            diasSemana: diasSemana.sorted()
        )
        repositorio(context).criar(lembrete)
    }

    func alternarAtivo(_ lembrete: Lembrete, context: ModelContext) {
        repositorio(context).alternarAtivo(lembrete)
    }

    func remover(_ lembrete: Lembrete, context: ModelContext) {
        repositorio(context).remover(lembrete)
    }

    func descricaoDias(_ lembrete: Lembrete) -> String {
        guard !lembrete.diasSemana.isEmpty, lembrete.diasSemana.count < 7 else { return "Todos os dias" }
        let nomes = Calendar.current.shortWeekdaySymbols
        return lembrete.diasSemana.map { nomes[$0 - 1] }.joined(separator: ", ")
    }

    private func repositorio(_ context: ModelContext) -> LembreteRepository {
        LembreteRepository(context: context, scheduler: scheduler)
    }
}
