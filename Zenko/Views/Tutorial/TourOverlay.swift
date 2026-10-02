import SwiftUI

/// Escurece a tela, recorta um "buraco" em volta do elemento real e mostra seta + balão explicativo.
struct TourOverlay: View {
    @Environment(TourController.self) private var tour
    /// Força recalcular a posição do alvo enquanto a troca de aba/layout termina.
    @State private var remedicao = 0
    /// Só depois de esgotar a procura o balão aparece centralizado, sem seta.
    @State private var procuraEsgotada = false

    var body: some View {
        if let indice = tour.passoAtual {
            GeometryReader { proxy in
                let _ = remedicao
                let origem = proxy.frame(in: .global).origin
                let passo = tour.passos[indice]
                let furo = tour.frame(de: passo.alvo)
                    .map { $0.offsetBy(dx: -origem.x, dy: -origem.y).insetBy(dx: -8, dy: -8) }
                    .flatMap { visivel($0, em: proxy.size) ? $0 : nil }

                ZStack {
                    Color.clear.contentShape(Rectangle())
                    fundo(furo: furo, tamanho: proxy.size)

                    if let furo {
                        destaque(furo)
                        seta(furo, tamanho: proxy.size)
                        balao(passo, indice: indice)
                            .frame(width: larguraBalao(proxy.size))
                            .padding(.leading, xBalao(furo, tamanho: proxy.size))
                            .padding(furoNaMetadeDeCima(furo, proxy.size) ? .top : .bottom,
                                     furoNaMetadeDeCima(furo, proxy.size) ? furo.maxY + 56 : proxy.size.height - furo.minY + 56)
                            .frame(maxWidth: .infinity, maxHeight: .infinity,
                                   alignment: furoNaMetadeDeCima(furo, proxy.size) ? .topLeading : .bottomLeading)
                    } else if procuraEsgotada {
                        balao(passo, indice: indice)
                            .frame(width: larguraBalao(proxy.size))
                    }
                }
                .animation(.spring(duration: 0.4), value: indice)
                .animation(.spring(duration: 0.3), value: remedicao)
            }
            .ignoresSafeArea()
            .task(id: indice) {
                procuraEsgotada = false
                // Procura o alvo por até 2s (troca de aba, layout, animação da barra).
                // Depois de achar, remede mais algumas vezes para pegar a posição final.
                var medicoesAposAchar = 0
                for _ in 0..<20 where medicoesAposAchar < 3 {
                    try? await Task.sleep(for: .milliseconds(100))
                    remedicao += 1
                    if tour.frame(de: tour.passos[indice].alvo) != nil { medicoesAposAchar += 1 }
                }
                if medicoesAposAchar == 0 { procuraEsgotada = true }
            }
            .transition(.opacity)
        }
    }

    // MARK: - Partes

    private func fundo(furo: CGRect?, tamanho: CGSize) -> some View {
        Path { caminho in
            caminho.addRect(CGRect(origin: .zero, size: tamanho))
            if let furo {
                caminho.addRoundedRect(in: furo, cornerSize: CGSize(width: 16, height: 16))
            }
        }
        .fill(Color.black.opacity(0.65), style: FillStyle(eoFill: true))
        .allowsHitTesting(false)
    }

    private func destaque(_ furo: CGRect) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(.tint, lineWidth: 3)
            .frame(width: furo.width, height: furo.height)
            .position(x: furo.midX, y: furo.midY)
            .allowsHitTesting(false)
    }

    private func seta(_ furo: CGRect, tamanho: CGSize) -> some View {
        let acima = furoNaMetadeDeCima(furo, tamanho)
        return Image(systemName: acima ? "arrowshape.up.fill" : "arrowshape.down.fill")
            .font(.system(size: 30))
            .foregroundStyle(.white)
            .shadow(radius: 4)
            .phaseAnimator([0.0, 1.0]) { conteudo, fase in
                conteudo.offset(y: (acima ? 6 : -6) * fase)
            } animation: { _ in
                .easeInOut(duration: 0.6)
            }
            .position(x: furo.midX, y: acima ? furo.maxY + 28 : furo.minY - 28)
            .allowsHitTesting(false)
            .accessibilityIdentifier("setaDoTour")
    }

    private func balao(_ passo: PassoTour, indice: Int) -> some View {
        let ultimo = indice == tour.passos.count - 1

        return VStack(alignment: .leading, spacing: 10) {
            if let imagem = passo.imagem {
                Image(imagem)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 72)
                    .frame(maxWidth: .infinity)
            }

            Text("\(indice + 1) de \(tour.passos.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)

            Text(passo.titulo)
                .font(.title3.bold())

            Text(passo.texto)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !passo.dicas.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(passo.dicas) { dica in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: dica.icone)
                                .foregroundStyle(dica.cor)
                                .frame(width: 20)
                            Text(dica.texto)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            HStack {
                if !ultimo {
                    Button("Pular") { withAnimation { tour.encerrar() } }
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(ultimo ? "Concluir" : "Próximo") {
                    withAnimation { tour.avancar() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
    }

    // MARK: - Geometria

    private func larguraBalao(_ tamanho: CGSize) -> CGFloat {
        min(tamanho.width - 32, 360)
    }

    private func xBalao(_ furo: CGRect, tamanho: CGSize) -> CGFloat {
        let largura = larguraBalao(tamanho)
        return min(max(furo.midX - largura / 2, 16), tamanho.width - 16 - largura)
    }

    private func furoNaMetadeDeCima(_ furo: CGRect, _ tamanho: CGSize) -> Bool {
        furo.midY < tamanho.height / 2
    }

    private func visivel(_ furo: CGRect, em tamanho: CGSize) -> Bool {
        furo.width > 16 && furo.height > 16 && CGRect(origin: .zero, size: tamanho).contains(CGPoint(x: furo.midX, y: furo.midY))
    }
}
