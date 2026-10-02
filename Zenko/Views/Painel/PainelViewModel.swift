import EventKit
import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class PainelViewModel {
    var importando = false
    var mensagem: String?

    private let classificador: ClassifierEngine
    private let calendario: CalendarioIntegracao

    init(classificador: ClassifierEngine? = nil, calendario: CalendarioIntegracao? = nil) {
        self.classificador = classificador ?? ClassifierEngine()
        self.calendario = calendario ?? CalendarioIntegracao()
    }

    func adicionarManual(titulo: String, conteudo: String, context: ModelContext) async {
        await registrar(titulo: titulo, conteudo: conteudo, origem: "manual", idExterno: nil, context: context)
    }

    func importarCalendario(context: ModelContext) async {
        importando = true
        defer { importando = false }

        guard await calendario.solicitarAcesso() else {
            mensagem = "Sem acesso ao Calendário. Libere em Ajustes > Privacidade > Calendários."
            return
        }

        let itens = ItemRepository(context: context)
        var novos = 0
        for evento in calendario.buscarEventosProximos() {
            guard let id = evento.eventIdentifier, !itens.existe(idExterno: id) else { continue }
            let quando = evento.startDate.formatted(date: .abbreviated, time: .shortened)
            await registrar(
                titulo: evento.title ?? "Evento",
                conteudo: [quando, evento.notes].compactMap { $0 }.joined(separator: " · "),
                origem: "calendario",
                idExterno: id,
                context: context
            )
            novos += 1
        }
        mensagem = novos == 0 ? "Nenhum evento novo nos próximos 7 dias." : "\(novos) evento(s) importado(s)."
    }

    func marcarComoLido(_ item: ItemRegistrado, context: ModelContext) {
        ItemRepository(context: context).marcarComoLido(item)
    }

    func remover(_ item: ItemRegistrado, context: ModelContext) {
        ItemRepository(context: context).remover(item)
    }

    private func registrar(titulo: String, conteudo: String, origem: String, idExterno: String?, context: ModelContext) async {
        let preferencias = PreferenciaRepository(context: context)
        let resultado = await classificador.classificar(
            titulo: titulo,
            conteudo: conteudo,
            origem: origem,
            regras: preferencias.regras(),
            preferencias: preferencias.carregarOuCriar()
        )
        ItemRepository(context: context).salvar(ItemRegistrado(
            titulo: titulo,
            conteudo: conteudo,
            origem: origem,
            idExterno: idExterno,
            pontuacaoImportancia: resultado.pontuacao,
            categoria: resultado.categoria
        ))
    }
}
