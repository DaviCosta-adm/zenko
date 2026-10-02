import SwiftUI

struct AparenciaView: View {
    @AppStorage(TemaStorage.modo) private var modo = ModoAparencia.sistema
    @AppStorage(TemaStorage.cor) private var cor = CorTema.zenko
    @AppStorage(TemaStorage.claroHora) private var claroHora = 7
    @AppStorage(TemaStorage.claroMinuto) private var claroMinuto = 0
    @AppStorage(TemaStorage.escuroHora) private var escuroHora = 19
    @AppStorage(TemaStorage.escuroMinuto) private var escuroMinuto = 0

    private let colunas = [GridItem(.adaptive(minimum: 80), spacing: 16)]

    var body: some View {
        Form {
            Section("Tema") {
                ForEach(ModoAparencia.allCases) { opcao in
                    Button {
                        withAnimation { modo = opcao }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: opcao.icone)
                                .font(.title3)
                                .foregroundStyle(.tint)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(opcao.nome).foregroundStyle(.primary)
                                Text(opcao.descricao)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if modo == opcao {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(opcao.nome)
                    .accessibilityHint(opcao.descricao)
                    .accessibilityAddTraits(modo == opcao ? .isSelected : [])
                }
            }

            if modo == .automatico {
                Section {
                    CampoHorario(titulo: "Claro a partir de", hora: $claroHora, minuto: $claroMinuto)
                    CampoHorario(titulo: "Escuro a partir de", hora: $escuroHora, minuto: $escuroMinuto)
                } header: {
                    Text("Horários")
                } footer: {
                    TimelineView(.everyMinute) { contexto in
                        let agora = TemaAutomatico.esquema(
                            em: contexto.date,
                            inicioClaro: (claroHora, claroMinuto),
                            inicioEscuro: (escuroHora, escuroMinuto)
                        )
                        Text(agora == .light ? "Agora o app está no tema claro." : "Agora o app está no tema escuro.")
                    }
                }
            }

            Section {
                LazyVGrid(columns: colunas, spacing: 16) {
                    ForEach(CorTema.allCases) { opcao in
                        Button {
                            withAnimation { cor = opcao }
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(opcao.cor)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if cor == opcao {
                                            Image(systemName: "checkmark")
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(4)
                                    .overlay {
                                        Circle().strokeBorder(cor == opcao ? opcao.cor : .clear, lineWidth: 2)
                                    }
                                Text(opcao.nome)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Cor \(opcao.nome)")
                        .accessibilityAddTraits(cor == opcao ? .isSelected : [])
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Cor do app")
            } footer: {
                Text("Usada em botões, abas e destaques. As cores de importância (vermelho, laranja, cinza) não mudam.")
            }

            Section("Prévia") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Boleto da luz").font(.headline)
                        Spacer()
                        Text("80%").foregroundStyle(.red)
                    }
                    Text("Vence amanhã").font(.subheadline).foregroundStyle(.secondary)
                    HStack {
                        Button("Botão principal") {}
                            .buttonStyle(.borderedProminent)
                        Button("Secundário") {}
                            .buttonStyle(.bordered)
                    }
                    Toggle("Lembrete ativo", isOn: .constant(true))
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Aparência")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AparenciaView()
    }
    .temaZenko()
}
