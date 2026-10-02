import SwiftUI

enum TutorialStorage {
    static let concluido = "tutorialConcluido"
}

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(TutorialStorage.concluido) private var concluido = false
    @State private var paginaAtual = 0

    private let paginas = PaginaTutorial.todas

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if paginaAtual < paginas.count - 1 {
                    Button("Pular", action: finalizar)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 44)
            .padding(.horizontal)

            TabView(selection: $paginaAtual) {
                ForEach(paginas) { pagina in
                    PaginaTutorialView(pagina: pagina)
                        .tag(pagina.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: avancar) {
                Text(paginaAtual == paginas.count - 1 ? "Começar a usar" : "Próximo")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }

    private func avancar() {
        if paginaAtual < paginas.count - 1 {
            withAnimation { paginaAtual += 1 }
        } else {
            finalizar()
        }
    }

    private func finalizar() {
        concluido = true
        dismiss()
    }
}

private struct PaginaTutorialView: View {
    let pagina: PaginaTutorial

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: pagina.icone)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(pagina.cor)
                    .frame(width: 110, height: 110)
                    .background(pagina.cor.opacity(0.12), in: Circle())
                    .padding(.top, 24)

                Text(pagina.titulo)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(pagina.texto)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if !pagina.dicas.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(pagina.dicas) { dica in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: dica.icone)
                                    .font(.title3)
                                    .foregroundStyle(dica.cor)
                                    .frame(width: 28)
                                Text(dica.texto)
                                    .font(.callout)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

struct PaginaTutorial: Identifiable {
    struct Dica: Identifiable {
        let id = UUID()
        let icone: String
        let cor: Color
        let texto: String
    }

    let id: Int
    let icone: String
    let cor: Color
    let titulo: String
    let texto: String
    var dicas: [Dica] = []

    static let todas: [PaginaTutorial] = [
        PaginaTutorial(
            id: 0,
            icone: "sparkles",
            cor: .accentColor,
            titulo: "Bem-vindo ao Zenko",
            texto: "O Zenko junta num só lugar o que precisa da sua atenção e te avisa na hora certa. Veja em 1 minuto como ele funciona."
        ),
        PaginaTutorial(
            id: 1,
            icone: "tray.full",
            cor: .blue,
            titulo: "Painel: o que importa hoje",
            texto: "É a primeira tela do app. Aqui ficam suas anotações e compromissos, os mais recentes no topo.",
            dicas: [
                .init(icone: "plus.circle.fill", cor: .blue, texto: "Toque no + (canto superior direito) para anotar algo: uma conta, uma reunião, um recado."),
                .init(icone: "hand.tap.fill", cor: .blue, texto: "Toque num item para marcá-lo como visto. Ele fica mais claro."),
                .init(icone: "hand.draw.fill", cor: .blue, texto: "Arraste um item para a esquerda para apagá-lo."),
            ]
        ),
        PaginaTutorial(
            id: 2,
            icone: "flag.fill",
            cor: .red,
            titulo: "O Zenko diz o que é urgente",
            texto: "Cada item recebe uma nota de importância, de 0% a 100%, mostrada ao lado do título. A cor ajuda a bater o olho:",
            dicas: [
                .init(icone: "circle.fill", cor: .red, texto: "Vermelho (70% ou mais): resolva logo. Ex: \"Boleto vence amanhã\"."),
                .init(icone: "circle.fill", cor: .orange, texto: "Laranja (40% a 69%): fique de olho."),
                .init(icone: "circle.fill", cor: .gray, texto: "Cinza (abaixo de 40%): pode esperar. Ex: \"Promoção da loja\"."),
            ]
        ),
        PaginaTutorial(
            id: 3,
            icone: "calendar.badge.plus",
            cor: .purple,
            titulo: "Traga sua agenda",
            texto: "Não precisa digitar seus compromissos de novo. O Zenko pode ler a agenda do iPhone.",
            dicas: [
                .init(icone: "calendar.badge.plus", cor: .purple, texto: "No Painel, toque no ícone de calendário (canto superior esquerdo)."),
                .init(icone: "clock.fill", cor: .purple, texto: "Ele traz os compromissos dos próximos 7 dias e já dá uma nota de importância para cada um."),
                .init(icone: "lock.fill", cor: .purple, texto: "O Zenko só lê sua agenda. Ele nunca altera nem apaga nada."),
            ]
        ),
        PaginaTutorial(
            id: 4,
            icone: "alarm.fill",
            cor: .orange,
            titulo: "Lembretes que se repetem",
            texto: "Na aba Lembretes, crie avisos em horários fixos. O iPhone avisa mesmo com o app fechado.",
            dicas: [
                .init(icone: "pills.fill", cor: .orange, texto: "\"Tomar remédio\" todo dia às 8h."),
                .init(icone: "doc.text.fill", cor: .orange, texto: "\"Enviar relatório\" toda sexta às 17h."),
                .init(icone: "switch.2", cor: .orange, texto: "Use a chave ao lado do lembrete para pausar sem apagar."),
            ]
        ),
        PaginaTutorial(
            id: 5,
            icone: "slider.horizontal.3",
            cor: .green,
            titulo: "Ensine o que importa pra você",
            texto: "Na aba Configurações, em \"Regras de importância\", diga ao Zenko quais palavras merecem atenção.",
            dicas: [
                .init(icone: "arrow.up.circle.fill", cor: .red, texto: "Nota positiva sobe a importância. Ex: o nome do seu maior cliente com +30."),
                .init(icone: "arrow.down.circle.fill", cor: .gray, texto: "Nota negativa baixa a importância. Ex: \"newsletter\" com -30."),
                .init(icone: "questionmark.circle.fill", cor: .green, texto: "Pode rever este tutorial quando quiser em Configurações."),
            ]
        ),
    ]
}

#Preview {
    TutorialView()
}
