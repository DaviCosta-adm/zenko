import SwiftUI
import SwiftData

struct ItemDetalheView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let item: ItemRegistrado
    var aoMarcarLido: (ItemRegistrado) -> Void
    var aoAlternarLido: (ItemRegistrado) -> Void
    var aoRemover: (ItemRegistrado) -> Void

    var body: some View {
        List {
            Section {
                Text(item.titulo)
                    .font(.title2.bold())
                if !item.conteudo.isEmpty {
                    Text(item.conteudo)
                        .font(.body)
                }
            }

            Section("Importância") {
                HStack {
                    Text("\(item.pontuacaoImportancia)%")
                        .font(.title.monospacedDigit().bold())
                        .foregroundStyle(ItemRotulos.cor(para: item.pontuacaoImportancia))
                    Text(rotuloImportancia)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Sobre") {
                LabeledContent("Categoria", value: ItemRotulos.categoria(item.categoria))
                LabeledContent("Origem", value: ItemRotulos.origem(item.origem))
                LabeledContent("Quando", value: item.timestamp.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Situação", value: item.lido ? "Já visto" : "Ainda não visto")
            }

            Section {
                Button {
                    aoAlternarLido(item)
                } label: {
                    Label(
                        item.lido ? "Marcar como não visto" : "Marcar como visto",
                        systemImage: item.lido ? "envelope.badge" : "envelope.open"
                    )
                }
                Button(role: .destructive) {
                    aoRemover(item)
                    dismiss()
                } label: {
                    Label("Apagar item", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Detalhe")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !item.lido { aoMarcarLido(item) }
        }
    }

    private var rotuloImportancia: String {
        switch item.pontuacaoImportancia {
        case 70...: "Urgente — resolva logo"
        case 40..<70: "Fique de olho"
        default: "Pode esperar"
        }
    }

}
