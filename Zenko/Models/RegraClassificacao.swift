import Foundation
import SwiftData

@Model
final class RegraClassificacao {
    var tipo: String       // "palavraChave" ou "origem"
    var valor: String
    var pesoAtribuido: Int // -50 a +50

    init(tipo: String, valor: String, pesoAtribuido: Int) {
        self.tipo = tipo
        self.valor = valor
        self.pesoAtribuido = pesoAtribuido
    }
}
