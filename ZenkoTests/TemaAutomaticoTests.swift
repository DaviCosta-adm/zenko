import SwiftUI
import XCTest
@testable import Zenko

@MainActor
final class TemaAutomaticoTests: XCTestCase {
    private var calendario: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return c
    }()

    private func data(_ hora: Int, _ minuto: Int = 0) -> Date {
        calendario.date(from: DateComponents(year: 2026, month: 10, day: 2, hour: hora, minute: minuto))!
    }

    private func esquema(_ hora: Int, _ minuto: Int = 0, claro: (Int, Int) = (7, 0), escuro: (Int, Int) = (19, 0)) -> ColorScheme {
        TemaAutomatico.esquema(em: data(hora, minuto), inicioClaro: claro, inicioEscuro: escuro, calendario: calendario)
    }

    func testDiaNormalClaroEntreSeteEDezenove() {
        XCTAssertEqual(esquema(6, 59), .dark)
        XCTAssertEqual(esquema(7, 0), .light)
        XCTAssertEqual(esquema(12), .light)
        XCTAssertEqual(esquema(18, 59), .light)
        XCTAssertEqual(esquema(19, 0), .dark)
        XCTAssertEqual(esquema(23), .dark)
    }

    func testPeriodoClaroQueAtravessaMeiaNoite() {
        let claro = (20, 0), escuro = (6, 0)
        XCTAssertEqual(esquema(21, claro: claro, escuro: escuro), .light)
        XCTAssertEqual(esquema(2, claro: claro, escuro: escuro), .light)
        XCTAssertEqual(esquema(6, claro: claro, escuro: escuro), .dark)
        XCTAssertEqual(esquema(15, claro: claro, escuro: escuro), .dark)
    }

    func testHorariosIguaisFicaSempreClaro() {
        XCTAssertEqual(esquema(3, claro: (8, 0), escuro: (8, 0)), .light)
    }
}
