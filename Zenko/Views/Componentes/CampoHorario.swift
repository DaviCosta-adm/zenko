import SwiftUI

/// DatePicker de hora/minuto ligado a dois `Int`, que é como os modelos guardam horários.
struct CampoHorario: View {
    let titulo: String
    @Binding var hora: Int
    @Binding var minuto: Int

    var body: some View {
        DatePicker(titulo, selection: data, displayedComponents: .hourAndMinute)
    }

    private var data: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: hora, minute: minuto)) ?? .now
            },
            set: { novaData in
                let componentes = Calendar.current.dateComponents([.hour, .minute], from: novaData)
                hora = componentes.hour ?? 0
                minuto = componentes.minute ?? 0
            }
        )
    }
}
