import Foundation
import SwiftData

@Model
final class ItemRegistrado {
    var titulo: String
    var conteudo: String
    var origem: String            // "manual", "calendario"
    var idExterno: String?        // ex: eventIdentifier do EventKit, evita importar duplicado
    var timestamp: Date
    var pontuacaoImportancia: Int // 0-100
    var categoria: String         // "financeiro", "trabalho", "pessoal", "outro"
    var lido: Bool

    init(
        titulo: String,
        conteudo: String,
        origem: String,
        idExterno: String? = nil,
        pontuacaoImportancia: Int,
        categoria: String
    ) {
        self.titulo = titulo
        self.conteudo = conteudo
        self.origem = origem
        self.idExterno = idExterno
        self.timestamp = Date()
        self.pontuacaoImportancia = pontuacaoImportancia
        self.categoria = categoria
        self.lido = false
    }
}
