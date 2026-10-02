import SwiftUI
import SwiftData

@main
struct ZenkoApp: App {
    var body: some Scene {
        WindowGroup {
            RaizView()
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
    }
}
