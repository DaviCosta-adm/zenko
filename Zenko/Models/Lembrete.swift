import Foundation
import SwiftData

@Model
final class Lembrete {
    var identificador: UUID
    var titulo: String
    var descricao: String?
    var hora: Int
    var minuto: Int
    var diasSemana: [Int]         // 1 = domingo ... 7 = sábado; vazio = todos os dias
    var ativo: Bool

    var horario: DateComponents {
        DateComponents(hour: hora, minute: minuto)
    }

    init(titulo: String, descricao: String? = nil, hora: Int, minuto: Int, diasSemana: [Int]) {
        self.identificador = UUID()
        self.titulo = titulo
        self.descricao = descricao
        self.hora = hora
        self.minuto = minuto
        self.diasSemana = diasSemana
        self.ativo = true
    }
}
