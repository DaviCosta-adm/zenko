import Observation
import SwiftUI
import UIKit

enum TutorialStorage {
    static let concluido = "tutorialConcluido"
}

enum AbaApp: Hashable {
    case painel, lembretes, configuracoes
}

/// Elementos reais da interface que o tour pode destacar.
enum AlvoTour: Hashable {
    case abaPainel, novoItem, exemploItem, importarCalendario, novoLembrete, aparencia, verTutorial

    /// Abas e botões de toolbar viram controles nativos do UIKit e descartam qualquer
    /// `.background`; eles são localizados pelo rótulo de acessibilidade (o texto do `Label`).
    var rotuloNativo: String? {
        switch self {
        case .abaPainel: "Painel"
        case .novoItem: "Novo item"
        case .importarCalendario: "Importar Calendário"
        case .novoLembrete: "Novo lembrete"
        case .exemploItem, .aparencia, .verTutorial: nil
        }
    }
}

struct PassoTour {
    struct Dica: Identifiable {
        let id = UUID()
        let icone: String
        let cor: Color
        let texto: String
    }

    let aba: AbaApp
    let alvo: AlvoTour
    var imagem: String? = nil
    let titulo: String
    let texto: String
    var dicas: [Dica] = []

    static let todos: [PassoTour] = [
        PassoTour(
            aba: .painel,
            alvo: .abaPainel,
            imagem: "LogoZenko",
            titulo: "Bem-vindo ao Zenko",
            texto: "Esta é a aba Painel, sua tela principal. Vou te mostrar em 30 segundos onde fica cada coisa."
        ),
        PassoTour(
            aba: .painel,
            alvo: .novoItem,
            titulo: "Anote o que importa",
            texto: "Toque no + para registrar uma conta, uma reunião ou um recado. O Zenko dá uma nota de importância sozinho."
        ),
        PassoTour(
            aba: .painel,
            alvo: .exemploItem,
            titulo: "Bata o olho na cor",
            texto: "Assim fica cada item no Painel, com uma nota de 0% a 100% à direita:",
            dicas: [
                .init(icone: "circle.fill", cor: .red, texto: "Vermelho: resolva logo."),
                .init(icone: "circle.fill", cor: .orange, texto: "Laranja: fique de olho."),
                .init(icone: "circle.fill", cor: .gray, texto: "Cinza: pode esperar."),
                .init(icone: "hand.tap.fill", cor: .secondary, texto: "Toque no item para marcar como visto; arraste para a esquerda para apagar."),
            ]
        ),
        PassoTour(
            aba: .painel,
            alvo: .importarCalendario,
            titulo: "Traga sua agenda",
            texto: "Toque aqui para importar os compromissos dos próximos 7 dias. O Zenko só lê sua agenda, nunca altera nada."
        ),
        PassoTour(
            aba: .lembretes,
            alvo: .novoLembrete,
            titulo: "Lembretes que se repetem",
            texto: "Aqui na aba Lembretes, toque no + para criar avisos fixos. Ex: \"Tomar remédio\" todo dia às 8h. O iPhone avisa mesmo com o app fechado."
        ),
        PassoTour(
            aba: .configuracoes,
            alvo: .aparencia,
            titulo: "Do seu jeito",
            texto: "Escolha tema claro, escuro ou automático pelo horário, e a cor do app."
        ),
        PassoTour(
            aba: .configuracoes,
            alvo: .verTutorial,
            titulo: "Pronto!",
            texto: "Mais abaixo nesta tela você ensina ao Zenko quais palavras são importantes. E pode rever este tour aqui quando quiser."
        ),
    ]
}

@MainActor
@Observable
final class TourController {
    var passoAtual: Int?
    var abaSelecionada: AbaApp = .painel

    let passos = PassoTour.todos

    var passo: PassoTour? {
        passoAtual.map { passos[$0] }
    }

    @ObservationIgnored private var fontes: [AlvoTour: ReferenciaFraca] = [:]

    /// Posição do alvo em coordenadas da janela, ou nil se ele não estiver na tela agora
    /// (ex: está numa aba que não é a selecionada).
    func frame(de alvo: AlvoTour) -> CGRect? {
        if let rotulo = alvo.rotuloNativo {
            return frameNaJanela(comRotulo: rotulo)
        }
        guard let view = fontes[alvo]?.view, let janela = view.window, !view.isHidden else { return nil }
        return view.convert(view.bounds, to: janela)
    }

    private func frameNaJanela(comRotulo rotulo: String) -> CGRect? {
        let janela = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        guard let janela else { return nil }

        func buscar(_ view: UIView) -> UIView? {
            if view.isHidden || view.alpha < 0.01 { return nil }
            if view.accessibilityLabel == rotulo, view.bounds.width > 1 { return view }
            for filha in view.subviews {
                if let achada = buscar(filha) { return achada }
            }
            return nil
        }
        return buscar(janela).map { $0.convert($0.bounds, to: janela) }
    }

    fileprivate func registrar(_ view: UIView, como alvo: AlvoTour) {
        fontes[alvo] = ReferenciaFraca(view: view)
    }

    func iniciar() {
        irPara(0)
    }

    func avancar() {
        guard let atual = passoAtual else { return }
        if atual + 1 < passos.count {
            irPara(atual + 1)
        } else {
            encerrar()
        }
    }

    func encerrar() {
        passoAtual = nil
        abaSelecionada = .painel
        UserDefaults.standard.set(true, forKey: TutorialStorage.concluido)
    }

    private func irPara(_ indice: Int) {
        abaSelecionada = passos[indice].aba
        passoAtual = indice
    }
}

private final class ReferenciaFraca {
    weak var view: UIView?
    init(view: UIView) { self.view = view }
}

/// Itens da barra de navegação são hospedados fora da hierarquia SwiftUI principal, então
/// `frame(in: .global)` não serve para eles. Uma UIView invisível atrás do alvo dá a posição
/// real na janela em qualquer lugar.
private struct MarcadorDePosicao: UIViewRepresentable {
    let aoEntrarNaJanela: (UIView) -> Void

    func makeUIView(context: Context) -> VisaoMarcadora {
        let view = VisaoMarcadora()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.aoEntrarNaJanela = aoEntrarNaJanela
        return view
    }

    func updateUIView(_ view: VisaoMarcadora, context: Context) {
        view.aoEntrarNaJanela = aoEntrarNaJanela
    }
}

private final class VisaoMarcadora: UIView {
    var aoEntrarNaJanela: ((UIView) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { aoEntrarNaJanela?(self) }
    }
}

private struct AlvoDoTour: ViewModifier {
    @Environment(TourController.self) private var tour: TourController?
    let alvo: AlvoTour

    func body(content: Content) -> some View {
        content.background {
            MarcadorDePosicao { [weak tour] view in
                tour?.registrar(view, como: alvo)
            }
        }
    }
}

extension View {
    /// Registra a posição na tela deste elemento para o tour poder apontar para ele.
    func alvoDoTour(_ alvo: AlvoTour) -> some View {
        modifier(AlvoDoTour(alvo: alvo))
    }
}
