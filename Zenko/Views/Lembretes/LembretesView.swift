import SwiftUI
import SwiftData

struct LembretesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Lembrete.hora), SortDescriptor(\Lembrete.minuto)]) var lembretes: [Lembrete]
    @State private var viewModel = LembretesViewModel()
    @State private var mostrandoNovo = false

    var body: some View {
        NavigationStack {
            List {
                if viewModel.permissaoNegada {
                    Label("Notificações desativadas. Ative em Ajustes > Zenko > Notificações.", systemImage: "bell.slash")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ForEach(lembretes) { lembrete in
                    Toggle(isOn: Binding(
                        get: { lembrete.ativo },
                        set: { _ in viewModel.alternarAtivo(lembrete, context: context) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%02d:%02d", lembrete.hora, lembrete.minuto))
                                .font(.title2.monospacedDigit())
                            Text(lembrete.titulo).font(.headline)
                            Text(viewModel.descricaoDias(lembrete))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indices in
                    indices.map { lembretes[$0] }.forEach { viewModel.remover($0, context: context) }
                }
            }
            .overlay {
                if lembretes.isEmpty {
                    ContentUnavailableView(
                        "Sem lembretes",
                        systemImage: "alarm",
                        description: Text("Crie lembretes em horários fixos.")
                    )
                }
            }
            .navigationTitle("Lembretes")
            .toolbar {
                Button { mostrandoNovo = true } label: {
                    Label("Novo lembrete", systemImage: "plus")
                }
            }
            .sheet(isPresented: $mostrandoNovo) {
                NovoLembreteView { titulo, descricao, hora, minuto, dias in
                    viewModel.criar(titulo: titulo, descricao: descricao, hora: hora, minuto: minuto, diasSemana: dias, context: context)
                }
            }
            .task { await viewModel.solicitarPermissao() }
        }
    }
}

private struct NovoLembreteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var titulo = ""
    @State private var descricao = ""
    @State private var hora = 9
    @State private var minuto = 0
    @State private var dias: Set<Int> = []
    let aoSalvar: (String, String, Int, Int, Set<Int>) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título", text: $titulo)
                    TextField("Descrição (opcional)", text: $descricao)
                }
                Section {
                    CampoHorario(titulo: "Horário", hora: $hora, minuto: $minuto)
                }
                Section {
                    ForEach(1...7, id: \.self) { dia in
                        Toggle(Calendar.current.weekdaySymbols[dia - 1].capitalized, isOn: Binding(
                            get: { dias.contains(dia) },
                            set: { marcado in
                                if marcado { dias.insert(dia) } else { dias.remove(dia) }
                            }
                        ))
                    }
                } header: {
                    Text("Repetir")
                } footer: {
                    Text("Sem nenhum dia marcado, o lembrete toca todos os dias.")
                }
            }
            .navigationTitle("Novo lembrete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        aoSalvar(titulo, descricao, hora, minuto, dias)
                        dismiss()
                    }
                    .disabled(titulo.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    LembretesView()
        .modelContainer(for: Lembrete.self, inMemory: true)
}
