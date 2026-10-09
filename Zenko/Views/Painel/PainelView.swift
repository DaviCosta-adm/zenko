import SwiftUI
import SwiftData

struct PainelView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ItemRegistrado.timestamp, order: .reverse) var itens: [ItemRegistrado]
    @Query private var preferencias: [PreferenciaUsuario]
    @State private var viewModel = PainelViewModel()
    @State private var mostrandoNovoItem = false
    @State private var agora = Date()
    @Environment(TourController.self) private var tour: TourController?
    @Environment(AuthController.self) private var auth: AuthController?

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

    private var tourAberto: Bool { tour?.passo != nil }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            lista(emSilencio: preferencias.first?.emSilencio(em: agora) ?? false)
            .background {
                TimelineView(.everyMinute) { contexto in
                    Color.clear
                        .onChange(of: contexto.date) { _, novo in agora = novo }
                }
            }
            .safeAreaInset(edge: .top) {
                if !tourAberto { filtros }
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
            .onAppear {
                viewModel.tokenDeAcesso = { [auth] in auth?.accessToken }
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

    private func lista(emSilencio: Bool) -> some View {
        @Bindable var viewModel = viewModel
        let visiveis = viewModel.itensVisiveis(itens, emSilencio: emSilencio)

        return List {
            if !tourAberto {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Buscar no painel", text: $viewModel.busca)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier("campoBuscaPainel")
                    }
                }
            }

            if emSilencio && !tourAberto {
                Section {
                    Label(
                        viewModel.mostrarTudoNoSilencio
                            ? "Horário de silêncio. Você pediu para ver tudo."
                            : "Horário de silêncio. Só o urgente (70% ou mais) aparece.",
                        systemImage: "moon.zzz.fill"
                    )
                    .font(.footnote)
                    Button(viewModel.mostrarTudoNoSilencio ? "Mostrar só o urgente" : "Ver todos os itens") {
                        viewModel.mostrarTudoNoSilencio.toggle()
                    }
                }
            }

            if mostrandoExemplo {
                linha(Self.itemExemplo)
                    .alvoDoTour(.exemploItem)
            }

            ForEach(visiveis) { item in
                NavigationLink {
                    ItemDetalheView(
                        item: item,
                        aoMarcarLido: { viewModel.marcarComoLido($0, context: context) },
                        aoAlternarLido: { viewModel.alternarLido($0, context: context) },
                        aoRemover: { viewModel.remover($0, context: context) }
                    )
                } label: {
                    linha(item)
                }
            }
            .onDelete { indices in
                indices.map { visiveis[$0] }.forEach { viewModel.remover($0, context: context) }
            }

            if visiveis.isEmpty && !mostrandoExemplo {
                ContentUnavailableView(
                    itens.isEmpty ? "Nada por aqui" : "Nenhum item neste filtro",
                    systemImage: itens.isEmpty ? "tray" : "line.3.horizontal.decrease.circle",
                    description: Text(itens.isEmpty
                        ? "Adicione um item ou importe eventos do Calendário."
                        : "Tente outra busca ou toque em Todos.")
                )
            }
        }
    }

    private var filtros: some View {
        @Bindable var viewModel = viewModel
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FiltroPainel.allCases) { filtro in
                    Button {
                        viewModel.filtro = filtro
                    } label: {
                        Text(filtro.titulo)
                            .font(.subheadline.weight(viewModel.filtro == filtro ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                viewModel.filtro == filtro ? Color.accentColor : Color(.secondarySystemFill),
                                in: Capsule()
                            )
                            .foregroundStyle(viewModel.filtro == filtro ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(viewModel.filtro == filtro ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func linha(_ item: ItemRegistrado) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.titulo).font(.headline)
                Spacer()
                Text("\(item.pontuacaoImportancia)%")
                    .foregroundStyle(ItemRotulos.cor(para: item.pontuacaoImportancia))
            }
            if !item.conteudo.isEmpty {
                Text(item.conteudo).font(.subheadline).lineLimit(2)
            }
            HStack {
                Text(ItemRotulos.categoria(item.categoria))
                Text("·")
                Text(ItemRotulos.origem(item.origem))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .opacity(item.lido ? 0.5 : 1)
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
