import EventKit
import Foundation
import Observation
import SwiftData

enum FiltroPainel: String, CaseIterable, Identifiable {
    case todos, naoLidos, financeiro, trabalho, pessoal, outro, calendario

    var id: String { rawValue }

    var titulo: String {
        switch self {
        case .todos: "Todos"
        case .naoLidos: "Não lidos"
        case .financeiro: "Financeiro"
        case .trabalho: "Trabalho"
        case .pessoal: "Pessoal"
        case .outro: "Outro"
        case .calendario: "Calendário"
        }
    }
}

@MainActor
@Observable
final class PainelViewModel {
    var importando = false
    var mensagem: String?
    var tokenDeAcesso: (() -> String?)?
    var busca = ""
    var filtro: FiltroPainel = .todos
    var mostrarTudoNoSilencio = false

    private let classificadorInjetado: ClassifierEngine?
    private let calendario: CalendarioIntegracao

    init(classificador: ClassifierEngine? = nil, calendario: CalendarioIntegracao? = nil) {
        self.classificadorInjetado = classificador
        self.calendario = calendario ?? CalendarioIntegracao()
    }

    private var classificador: ClassifierEngine {
        classificadorInjetado ?? ClassifierEngine(
            classificadorAPI: ClassificadorAPI(tokenDeAcesso: { [weak self] in self?.tokenDeAcesso?() })
        )
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

    func alternarLido(_ item: ItemRegistrado, context: ModelContext) {
        ItemRepository(context: context).alternarLido(item)
    }

    func remover(_ item: ItemRegistrado, context: ModelContext) {
        ItemRepository(context: context).remover(item)
    }

    func itensVisiveis(_ itens: [ItemRegistrado], emSilencio: Bool) -> [ItemRegistrado] {
        Self.filtrar(
            itens,
            busca: busca,
            filtro: filtro,
            emSilencio: emSilencio,
            mostrarTudoNoSilencio: mostrarTudoNoSilencio
        )
    }

    static func filtrar(
        _ itens: [ItemRegistrado],
        busca: String,
        filtro: FiltroPainel,
        emSilencio: Bool,
        mostrarTudoNoSilencio: Bool
    ) -> [ItemRegistrado] {
        let texto = busca.trimmingCharacters(in: .whitespacesAndNewlines)
        return itens.filter { item in
            if emSilencio && !mostrarTudoNoSilencio && item.pontuacaoImportancia < 70 {
                return false
            }
            switch filtro {
            case .todos: break
            case .naoLidos: if item.lido { return false }
            case .financeiro, .trabalho, .pessoal, .outro:
                if item.categoria != filtro.rawValue { return false }
            case .calendario:
                if item.origem != "calendario" { return false }
            }
            guard !texto.isEmpty else { return true }
            return item.titulo.localizedCaseInsensitiveContains(texto)
                || item.conteudo.localizedCaseInsensitiveContains(texto)
                || item.categoria.localizedCaseInsensitiveContains(texto)
        }
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
