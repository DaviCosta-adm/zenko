import SwiftUI
import SwiftData

@main
struct ZenkoApp: App {
    init() {
        let argumentos = ProcessInfo.processInfo.arguments
        if argumentos.contains("-uitesting-pular-tutorial") {
            UserDefaults.standard.set(true, forKey: TutorialStorage.concluido)
        } else if argumentos.contains("-uitesting-mostrar-tutorial") {
            UserDefaults.standard.set(false, forKey: TutorialStorage.concluido)
        }
    }

    @State private var auth = AuthController()

    var body: some Scene {
        WindowGroup {
            PortaoDeLogin()
                .environment(auth)
                .temaZenko()
        }
        .modelContainer(for: [
            ItemRegistrado.self,
            Lembrete.self,
            RegraClassificacao.self,
            PreferenciaUsuario.self,
        ])
    }
}

/// O app só abre depois do login.
private struct PortaoDeLogin: View {
    @Environment(AuthController.self) private var auth

    var body: some View {
        Group {
            switch auth.estado {
            case .carregando:
                Image("LogoZenko")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
            case .deslogado:
                LoginView()
                    .transition(.opacity)
            case .logado:
                RaizView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.estado)
        .task { await auth.restaurar() }
    }
}

private struct RaizView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(TutorialStorage.concluido) private var tutorialConcluido = false
    @State private var tour = TourController()

    var body: some View {
        TabView(selection: $tour.abaSelecionada) {
            PainelView()
                .tabItem { Label("Painel", systemImage: "tray.full") }
                .tag(AbaApp.painel)
            LembretesView()
                .tabItem { Label("Lembretes", systemImage: "alarm") }
                .tag(AbaApp.lembretes)
            ConfiguracoesView()
                .tabItem { Label("Configurações", systemImage: "gearshape") }
                .tag(AbaApp.configuracoes)
        }
        .overlay { TourOverlay() }
        .environment(tour)
        .task {
            PreferenciaRepository(context: context).carregarOuCriar()
            #if DEBUG
            // Abre o tour direto num passo, sem XCUITest (que liga a acessibilidade e mascara bugs).
            let argumentos = ProcessInfo.processInfo.arguments
            if let posicao = argumentos.firstIndex(of: "-tour-passo"), posicao + 1 < argumentos.count,
               let passo = Int(argumentos[posicao + 1]) {
                try? await Task.sleep(for: .milliseconds(400))
                tour.iniciar(noPasso: passo)
                return
            }
            #endif
            if !tutorialConcluido {
                try? await Task.sleep(for: .milliseconds(400))
                withAnimation { tour.iniciar() }
            }
        }
    }
}
