import SwiftUI
import SwiftData

struct ConfiguracoesView: View {
    @Environment(\.modelContext) private var context
    @Query private var preferencias: [PreferenciaUsuario]
    @Query(sort: \RegraClassificacao.valor) private var regras: [RegraClassificacao]
    @State private var viewModel = ConfiguracoesViewModel()
    @State private var novaPalavra = ""
    @State private var novoPeso = 20

    var body: some View {
        NavigationStack {
            Form {
                if let preferencia = preferencias.first {
                    secaoPreferencias(preferencia)
                }
                secaoRegras
            }
            .navigationTitle("Configurações")
            .task { viewModel.garantirPreferencias(context: context) }
        }
    }

    private func secaoPreferencias(_ preferencia: PreferenciaUsuario) -> some View {
        @Bindable var preferencia = preferencia
        return Group {
            Section("Horário de silêncio") {
                CampoHorario(titulo: "Início", hora: $preferencia.silencioInicioHora, minuto: $preferencia.silencioInicioMinuto)
                CampoHorario(titulo: "Fim", hora: $preferencia.silencioFimHora, minuto: $preferencia.silencioFimMinuto)
            }
            Section {
                Slider(
                    value: Binding(
                        get: { Double(preferencia.sensibilidadeIA) },
                        set: { preferencia.sensibilidadeIA = Int($0) }
                    ),
                    in: 0...100,
                    step: 5
                ) {
                    Text("Sensibilidade")
                }
                Text("Ponto central: \(preferencia.sensibilidadeIA)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Sensibilidade da IA")
            } footer: {
                Text("Itens cuja pontuação pelas regras fica perto desse valor são enviados à IA para desempate.")
            }
        }
    }

    private var secaoRegras: some View {
        Section {
            ForEach(regras) { regra in
                HStack {
                    Text(regra.valor)
                    Spacer()
                    Text(regra.pesoAtribuido > 0 ? "+\(regra.pesoAtribuido)" : "\(regra.pesoAtribuido)")
                        .monospacedDigit()
                        .foregroundStyle(regra.pesoAtribuido > 0 ? .red : .secondary)
                }
            }
            .onDelete { indices in
                indices.map { regras[$0] }.forEach { viewModel.removerRegra($0, context: context) }
            }

            HStack {
                TextField("Nova palavra-chave", text: $novaPalavra)
                Stepper("\(novoPeso)", value: $novoPeso, in: -50...50, step: 10)
                    .fixedSize()
                Button {
                    viewModel.adicionarRegra(palavra: novaPalavra, peso: novoPeso, context: context)
                    novaPalavra = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(novaPalavra.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Text("Regras de importância")
        } footer: {
            Text("Cada palavra encontrada soma (ou subtrai) o peso na pontuação do item, que começa em 50.")
        }
    }
}

#Preview {
    ConfiguracoesView()
        .modelContainer(for: [PreferenciaUsuario.self, RegraClassificacao.self], inMemory: true)
}
