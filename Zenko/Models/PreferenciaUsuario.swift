import Foundation
import SwiftData

@Model
final class PreferenciaUsuario {
    var silencioInicioHora: Int
    var silencioInicioMinuto: Int
    var silencioFimHora: Int
    var silencioFimMinuto: Int
    var sensibilidadeIA: Int // 0-100

    var horarioSilencioInicio: DateComponents {
        DateComponents(hour: silencioInicioHora, minute: silencioInicioMinuto)
    }

    var horarioSilencioFim: DateComponents {
        DateComponents(hour: silencioFimHora, minute: silencioFimMinuto)
    }

    init(
        silencioInicioHora: Int = 22,
        silencioInicioMinuto: Int = 0,
        silencioFimHora: Int = 7,
        silencioFimMinuto: Int = 0,
        sensibilidadeIA: Int = 50
    ) {
        self.silencioInicioHora = silencioInicioHora
        self.silencioInicioMinuto = silencioInicioMinuto
        self.silencioFimHora = silencioFimHora
        self.silencioFimMinuto = silencioFimMinuto
        self.sensibilidadeIA = sensibilidadeIA
    }
}
