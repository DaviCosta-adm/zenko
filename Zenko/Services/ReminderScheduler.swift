import Foundation
import UserNotifications

final class ReminderScheduler {

    func solicitarPermissao() async -> Bool {
        let centro = UNUserNotificationCenter.current()
        return (try? await centro.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func permissaoFoiNegada() async -> Bool {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied
    }

    func agendar(_ lembrete: Lembrete, silencio: PreferenciaUsuario? = nil) {
        guard lembrete.ativo else { return }
        if let silencio, HorarioSilencio.horarioCaiNoPeriodo(
            hora: lembrete.hora,
            minuto: lembrete.minuto,
            inicio: silencio.silencioInicio,
            fim: silencio.silencioFim
        ) {
            cancelar(lembrete)
            return
        }

        let conteudo = UNMutableNotificationContent()
        conteudo.title = "⏰ \(lembrete.titulo)"
        conteudo.body = lembrete.descricao ?? ""
        conteudo.sound = .default

        for dia in diasAgendados(lembrete) {
            var componentes = lembrete.horario
            componentes.weekday = dia

            let trigger = UNCalendarNotificationTrigger(dateMatching: componentes, repeats: true)
            let request = UNNotificationRequest(
                identifier: identificador(lembrete, dia: dia),
                content: conteudo,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelar(_ lembrete: Lembrete) {
        let todosOsDias: [Int?] = [nil] + (1...7).map { $0 }
        let identificadores = todosOsDias.map { identificador(lembrete, dia: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identificadores)
    }

    /// Sem dias marcados, agenda um único disparo diário (weekday = nil).
    private func diasAgendados(_ lembrete: Lembrete) -> [Int?] {
        lembrete.diasSemana.isEmpty ? [nil] : lembrete.diasSemana.map { $0 }
    }

    private func identificador(_ lembrete: Lembrete, dia: Int?) -> String {
        "lembrete_\(lembrete.identificador.uuidString)_\(dia.map(String.init) ?? "diario")"
    }
}
