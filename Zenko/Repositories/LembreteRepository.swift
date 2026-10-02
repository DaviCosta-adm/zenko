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
        scheduler.agendar(lembrete)
    }

    func alternarAtivo(_ lembrete: Lembrete) {
        lembrete.ativo.toggle()
        try? context.save()
        if lembrete.ativo {
            scheduler.agendar(lembrete)
        } else {
            scheduler.cancelar(lembrete)
        }
    }

    func remover(_ lembrete: Lembrete) {
        scheduler.cancelar(lembrete)
        context.delete(lembrete)
        try? context.save()
    }
}
