import Foundation

enum HorarioSilencio {
    /// Início e fim iguais = silêncio desligado.
    static func ativo(
        em data: Date = .now,
        inicio: (hora: Int, minuto: Int),
        fim: (hora: Int, minuto: Int),
        calendario: Calendar = .current
    ) -> Bool {
        let agora = calendario.dateComponents([.hour, .minute], from: data)
        return horarioCaiNoPeriodo(
            hora: agora.hour ?? 0,
            minuto: agora.minute ?? 0,
            inicio: inicio,
            fim: fim
        )
    }

    /// Um horário fixo (ex: 23:00 de um lembrete) cai dentro da janela de silêncio.
    /// Funciona também quando a janela atravessa a meia-noite (22h → 7h).
    static func horarioCaiNoPeriodo(
        hora: Int,
        minuto: Int,
        inicio: (hora: Int, minuto: Int),
        fim: (hora: Int, minuto: Int)
    ) -> Bool {
        let atual = hora * 60 + minuto
        let comeco = inicio.hora * 60 + inicio.minuto
        let termo = fim.hora * 60 + fim.minuto
        if comeco == termo { return false }
        if comeco < termo {
            return (comeco..<termo).contains(atual)
        }
        return atual >= comeco || atual < termo
    }
}

extension PreferenciaUsuario {
    var silencioInicio: (hora: Int, minuto: Int) {
        (silencioInicioHora, silencioInicioMinuto)
    }

    var silencioFim: (hora: Int, minuto: Int) {
        (silencioFimHora, silencioFimMinuto)
    }

    func emSilencio(em data: Date = .now, calendario: Calendar = .current) -> Bool {
        HorarioSilencio.ativo(em: data, inicio: silencioInicio, fim: silencioFim, calendario: calendario)
    }
}
