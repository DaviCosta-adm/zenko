import SwiftUI
import SwiftData

struct PainelView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ItemRegistrado.timestamp, order: .reverse) var itens: [ItemRegistrado]
    @State private var viewModel = PainelViewModel()
    @State private var mostrandoNovoItem = false
    @Environment(TourController.self) private var tour: TourController?

    /// Item fictício (não salvo) mostrado só durante o passo do tour que explica as cores.
    private static let itemExemplo = ItemRegistrado(
        titulo: "Boleto da luz (exemplo)",
        conteudo: "Vence amanhã",
        origem: "manual",
        pontuacaoImportancia: 85,
        categoria: "financeiro"
    )

    private var mostrandoExemplo: Bool {
        tour?.passo?.alvo == .exemploItem
    }

    var body: some View {
        NavigationStack {
            List {
                if mostrandoExemplo {
                    linha(Self.itemExemplo)
                        .alvoDoTour(.exemploItem)
                }
                ForEach(itens) { item in
                    linha(item)
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.marcarComoLido(item, context: context) }
                }
                .onDelete { indices in
                    indices.map { itens[$0] }.forEach { viewModel.remover($0, context: context) }
                }
            }
            .overlay {
                if itens.isEmpty && !mostrandoExemplo {
                    ContentUnavailableView(
                        "Nada por aqui",
                        systemImage: "tray",
                        description: Text("Adicione um item ou importe eventos do Calendário.")
                    )
                }
            }
            .navigationTitle("Zenko")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await viewModel.importarCalendario(context: context) }
                    } label: {
                        Label("Importar Calendário", systemImage: "calendar.badge.plus")
                    }
                    .disabled(viewModel.importando)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { mostrandoNovoItem = true } label: {
                        Label("Novo item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $mostrandoNovoItem) {
                NovoItemView { titulo, conteudo in
                    Task { await viewModel.adicionarManual(titulo: titulo, conteudo: conteudo, context: context) }
                }
            }
            .alert(
                viewModel.mensagem ?? "",
                isPresented: Binding(
                    get: { viewModel.mensagem != nil },
                    set: { if !$0 { viewModel.mensagem = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func linha(_ item: ItemRegistrado) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.titulo).font(.headline)
                Spacer()
                Text("\(item.pontuacaoImportancia)%")
                    .foregroundStyle(cor(para: item.pontuacaoImportancia))
            }
            Text(item.conteudo).font(.subheadline).lineLimit(2)
            HStack {
                Text(item.categoria)
                Text("·")
                Text(item.origem)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .opacity(item.lido ? 0.5 : 1)
    }

    func cor(para pontuacao: Int) -> Color {
        switch pontuacao {
        case 70...: return .red
        case 40..<70: return .orange
        default: return .gray
        }
    }
}

private struct NovoItemView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var titulo = ""
    @State private var conteudo = ""
    let aoSalvar: (String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Título", text: $titulo)
                TextField("Detalhes", text: $conteudo, axis: .vertical)
                    .lineLimit(3...6)
            }
            .navigationTitle("Novo item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        aoSalvar(titulo, conteudo)
                        dismiss()
                    }
                    .disabled(titulo.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    PainelView()
        .modelContainer(for: [ItemRegistrado.self, RegraClassificacao.self, PreferenciaUsuario.self], inMemory: true)
}
