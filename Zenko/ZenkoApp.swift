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

    var body: some View {
        TabView {
            PainelView()
                .tabItem { Label("Painel", systemImage: "tray.full") }
            LembretesView()
                .tabItem { Label("Lembretes", systemImage: "alarm") }
            ConfiguracoesView()
                .tabItem { Label("Configurações", systemImage: "gearshape") }
        }
        .task { PreferenciaRepository(context: context).carregarOuCriar() }
        .fullScreenCover(isPresented: Binding(
            get: { !tutorialConcluido },
            set: { tutorialConcluido = !$0 }
        )) {
            TutorialView()
                .temaZenko()
        }
    }
}
