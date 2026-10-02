import Foundation
import EventKit

final class CalendarioIntegracao {
    private let store = EKEventStore()

    func solicitarAcesso() async -> Bool {
        (try? await store.requestFullAccessToEvents()) ?? false
    }

    func buscarEventosProximos(dias: Int = 7) -> [EKEvent] {
        let inicio = Date()
        guard let fim = Calendar.current.date(byAdding: .day, value: dias, to: inicio) else { return [] }
        let predicate = store.predicateForEvents(withStart: inicio, end: fim, calendars: nil)
        return store.events(matching: predicate)
    }
}
