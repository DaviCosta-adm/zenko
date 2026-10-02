import SwiftUI

enum TemaStorage {
    static let modo = "temaModo"
    static let cor = "temaCor"
    static let claroHora = "temaClaroHora"
    static let claroMinuto = "temaClaroMinuto"
    static let escuroHora = "temaEscuroHora"
    static let escuroMinuto = "temaEscuroMinuto"
}

enum ModoAparencia: String, CaseIterable, Identifiable {
    case sistema, claro, escuro, automatico

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .sistema: "Igual ao iPhone"
        case .claro: "Claro"
        case .escuro: "Escuro"
        case .automatico: "Automático pelo horário"
        }
    }

    var descricao: String {
        switch self {
        case .sistema: "Segue o modo claro/escuro definido nos Ajustes do iPhone."
        case .claro: "Fundo branco o tempo todo."
        case .escuro: "Fundo escuro o tempo todo, mais confortável à noite."
        case .automatico: "Claro durante o dia e escuro à noite, nos horários que você escolher."
        }
    }

    var icone: String {
        switch self {
        case .sistema: "iphone"
        case .claro: "sun.max.fill"
        case .escuro: "moon.fill"
        case .automatico: "clock.fill"
        }
    }
}

enum CorTema: String, CaseIterable, Identifiable {
    case zenko, oceano, esmeralda, ambar, coral, lavanda

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .zenko: "Zenko"
        case .oceano: "Oceano"
        case .esmeralda: "Esmeralda"
        case .ambar: "Âmbar"
        case .coral: "Coral"
        case .lavanda: "Lavanda"
        }
    }

    var cor: Color {
        switch self {
        case .zenko: Color(red: 0.31, green: 0.39, blue: 0.93)
        case .oceano: Color(red: 0.00, green: 0.58, blue: 0.74)
        case .esmeralda: Color(red: 0.13, green: 0.62, blue: 0.40)
        case .ambar: Color(red: 0.93, green: 0.55, blue: 0.10)
        case .coral: Color(red: 0.93, green: 0.36, blue: 0.40)
        case .lavanda: Color(red: 0.58, green: 0.40, blue: 0.90)
        }
    }
}

enum TemaAutomatico {
    /// Claro de `inicioClaro` até `inicioEscuro`; escuro no resto do dia. Funciona também
    /// quando o período claro atravessa a meia-noite (ex: claro das 20h às 6h).
    static func esquema(
        em data: Date,
        inicioClaro: (hora: Int, minuto: Int),
        inicioEscuro: (hora: Int, minuto: Int),
        calendario: Calendar = .current
    ) -> ColorScheme {
        let agora = calendario.dateComponents([.hour, .minute], from: data)
        let minutoAtual = (agora.hour ?? 0) * 60 + (agora.minute ?? 0)
        let claro = inicioClaro.hora * 60 + inicioClaro.minuto
        let escuro = inicioEscuro.hora * 60 + inicioEscuro.minuto

        if claro == escuro { return .light }
        let dentroDoClaro = claro < escuro
            ? (claro..<escuro).contains(minutoAtual)
            : !(escuro..<claro).contains(minutoAtual)
        return dentroDoClaro ? .light : .dark
    }
}

/// Aplica tema (claro/escuro/automático) e cor escolhidos em toda a hierarquia.
struct TemaAplicado: ViewModifier {
    @AppStorage(TemaStorage.modo) private var modo = ModoAparencia.sistema
    @AppStorage(TemaStorage.cor) private var cor = CorTema.zenko
    @AppStorage(TemaStorage.claroHora) private var claroHora = 7
    @AppStorage(TemaStorage.claroMinuto) private var claroMinuto = 0
    @AppStorage(TemaStorage.escuroHora) private var escuroHora = 19
    @AppStorage(TemaStorage.escuroMinuto) private var escuroMinuto = 0

    func body(content: Content) -> some View {
        TimelineView(.everyMinute) { contexto in
            content
                .preferredColorScheme(esquema(em: contexto.date))
                .tint(cor.cor)
        }
    }

    private func esquema(em data: Date) -> ColorScheme? {
        switch modo {
        case .sistema: nil
        case .claro: .light
        case .escuro: .dark
        case .automatico:
            TemaAutomatico.esquema(
                em: data,
                inicioClaro: (claroHora, claroMinuto),
                inicioEscuro: (escuroHora, escuroMinuto)
            )
        }
    }
}

extension View {
    func temaZenko() -> some View {
        modifier(TemaAplicado())
    }
}
