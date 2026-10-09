import Foundation
import SwiftData

@MainActor
final class LembreteRepository {
    private let context: ModelContext
    private let scheduler: ReminderScheduler

    init(context: ModelContext, scheduler: ReminderScheduler? = nil) {
        self.context = context
        self.scheduler = scheduler ?? ReminderScheduler()
    }

    func criar(_ lembrete: Lembrete) {
        context.insert(lembrete)
        try? context.save()
        scheduler.agendar(lembrete, silencio: silencioAtual())
    }

    func alternarAtivo(_ lembrete: Lembrete) {
        lembrete.ativo.toggle()
        try? context.save()
        if lembrete.ativo {
            scheduler.agendar(lembrete, silencio: silencioAtual())
        } else {
            scheduler.cancelar(lembrete)
        }
    }

    func reagendarTodos() {
        let lembretes = (try? context.fetch(FetchDescriptor<Lembrete>())) ?? []
        let silencio = silencioAtual()
        for lembrete in lembretes {
            scheduler.cancelar(lembrete)
            scheduler.agendar(lembrete, silencio: silencio)
        }
    }

    private func silencioAtual() -> PreferenciaUsuario {
        PreferenciaRepository(context: context).carregarOuCriar()
    }

    func remover(_ lembrete: Lembrete) {
        scheduler.cancelar(lembrete)
        context.delete(lembrete)
        try? context.save()
    }
}
