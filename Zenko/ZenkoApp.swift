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

    var body: some Scene {
        WindowGroup {
            RaizView()
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
            if !tutorialConcluido {
                try? await Task.sleep(for: .milliseconds(400))
                withAnimation { tour.iniciar() }
            }
        }
    }
}
