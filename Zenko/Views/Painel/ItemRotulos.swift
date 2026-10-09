import SwiftUI

enum ItemRotulos {
    static func categoria(_ valor: String) -> String {
        switch valor {
        case "financeiro": "Financeiro"
        case "trabalho": "Trabalho"
        case "pessoal": "Pessoal"
        default: "Outro"
        }
    }

    static func origem(_ valor: String) -> String {
        switch valor {
        case "calendario": "Calendário"
        default: "Você anotou"
        }
    }

    static func cor(para pontuacao: Int) -> Color {
        switch pontuacao {
        case 70...: .red
        case 40..<70: .orange
        default: .gray
        }
    }
}
