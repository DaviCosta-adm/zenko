import XCTest
@testable import Zenko

@MainActor
final class HorarioSilencioTests: XCTestCase {
    func testJanelaNoturnaAtravessaMeiaNoite() {
        let inicio = (hora: 22, minuto: 0)
        let fim = (hora: 7, minuto: 0)

        XCTAssertTrue(HorarioSilencio.horarioCaiNoPeriodo(hora: 22, minuto: 0, inicio: inicio, fim: fim))
        XCTAssertTrue(HorarioSilencio.horarioCaiNoPeriodo(hora: 23, minuto: 30, inicio: inicio, fim: fim))
        XCTAssertTrue(HorarioSilencio.horarioCaiNoPeriodo(hora: 3, minuto: 0, inicio: inicio, fim: fim))
        XCTAssertFalse(HorarioSilencio.horarioCaiNoPeriodo(hora: 7, minuto: 0, inicio: inicio, fim: fim))
        XCTAssertFalse(HorarioSilencio.horarioCaiNoPeriodo(hora: 9, minuto: 0, inicio: inicio, fim: fim))
        XCTAssertFalse(HorarioSilencio.horarioCaiNoPeriodo(hora: 21, minuto: 59, inicio: inicio, fim: fim))
    }

    func testJanelaDeTardeNaoAtravessaMeiaNoite() {
        let inicio = (hora: 13, minuto: 0)
        let fim = (hora: 15, minuto: 0)

        XCTAssertTrue(HorarioSilencio.horarioCaiNoPeriodo(hora: 13, minuto: 0, inicio: inicio, fim: fim))
        XCTAssertTrue(HorarioSilencio.horarioCaiNoPeriodo(hora: 14, minuto: 30, inicio: inicio, fim: fim))
        XCTAssertFalse(HorarioSilencio.horarioCaiNoPeriodo(hora: 15, minuto: 0, inicio: inicio, fim: fim))
        XCTAssertFalse(HorarioSilencio.horarioCaiNoPeriodo(hora: 23, minuto: 0, inicio: inicio, fim: fim))
    }

    func testInicioIgualAoFimDesligaOSilencio() {
        let mesmo = (hora: 8, minuto: 0)
        XCTAssertFalse(HorarioSilencio.horarioCaiNoPeriodo(hora: 8, minuto: 0, inicio: mesmo, fim: mesmo))
        XCTAssertFalse(HorarioSilencio.horarioCaiNoPeriodo(hora: 3, minuto: 0, inicio: mesmo, fim: mesmo))
    }

    func testFiltroEscondeBaixaPrioridadeNoSilencio() {
        let urgente = ItemRegistrado(titulo: "Boleto", conteudo: "", origem: "manual", pontuacaoImportancia: 80, categoria: "financeiro")
        let baixo = ItemRegistrado(titulo: "Promo", conteudo: "", origem: "manual", pontuacaoImportancia: 20, categoria: "pessoal")

        let soUrgente = PainelViewModel.filtrar([urgente, baixo], busca: "", filtro: .todos, emSilencio: true, mostrarTudoNoSilencio: false)
        XCTAssertEqual(soUrgente.map(\.titulo), ["Boleto"])

        let todos = PainelViewModel.filtrar([urgente, baixo], busca: "", filtro: .todos, emSilencio: true, mostrarTudoNoSilencio: true)
        XCTAssertEqual(todos.count, 2)
    }

    func testFiltroPorCategoriaEBusca() {
        let boleto = ItemRegistrado(titulo: "Boleto da luz", conteudo: "Vence", origem: "manual", pontuacaoImportancia: 80, categoria: "financeiro")
        let reuniao = ItemRegistrado(titulo: "Reunião", conteudo: "Sala 3", origem: "calendario", pontuacaoImportancia: 55, categoria: "trabalho")
        reuniao.lido = true

        let financeiros = PainelViewModel.filtrar([boleto, reuniao], busca: "", filtro: .financeiro, emSilencio: false, mostrarTudoNoSilencio: false)
        XCTAssertEqual(financeiros.map(\.titulo), ["Boleto da luz"])

        let naoLidos = PainelViewModel.filtrar([boleto, reuniao], busca: "", filtro: .naoLidos, emSilencio: false, mostrarTudoNoSilencio: false)
        XCTAssertEqual(naoLidos.map(\.titulo), ["Boleto da luz"])

        let busca = PainelViewModel.filtrar([boleto, reuniao], busca: "sala", filtro: .todos, emSilencio: false, mostrarTudoNoSilencio: false)
        XCTAssertEqual(busca.map(\.titulo), ["Reunião"])

        let agenda = PainelViewModel.filtrar([boleto, reuniao], busca: "", filtro: .calendario, emSilencio: false, mostrarTudoNoSilencio: false)
        XCTAssertEqual(agenda.map(\.titulo), ["Reunião"])
    }
}
