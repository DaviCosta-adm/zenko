import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @Environment(AuthController.self) private var auth
    @Environment(\.colorScheme) private var esquema
    @State private var viewModel = LoginViewModel()
    @FocusState private var campoFocado: Campo?

    private enum Campo { case email, senha }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(spacing: 24) {
                cabecalho

                Picker("Modo", selection: $viewModel.modo) {
                    ForEach(LoginViewModel.Modo.allCases) { modo in
                        Text(modo.titulo).tag(modo)
                    }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    campoEmail
                    campoSenha
                    if viewModel.modo == .criarConta {
                        Text("Mínimo de 6 caracteres.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                mensagens

                VStack(spacing: 12) {
                    Button {
                        Task { await viewModel.enviar(auth: auth) }
                    } label: {
                        Group {
                            if viewModel.carregando {
                                ProgressView().tint(.white)
                            } else {
                                Text(viewModel.modo.titulo).font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 28)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.carregando)
                    .accessibilityIdentifier("botaoEnviar")

                    if viewModel.modo == .entrar {
                        Button("Esqueci minha senha") {
                            Task { await viewModel.esqueciSenha(auth: auth) }
                        }
                        .font(.subheadline)
                        .disabled(viewModel.carregando)
                    }
                }

                separador

                SignInWithAppleButton(viewModel.modo == .entrar ? .signIn : .signUp) { request in
                    viewModel.prepararApple(request)
                } onCompletion: { resultado in
                    Task { await viewModel.concluirApple(resultado, auth: auth) }
                }
                .signInWithAppleButtonStyle(esquema == .dark ? .white : .black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .id(esquema)

                if !auth.configurado {
                    avisoSemServidor
                }
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .animation(.default, value: viewModel.modo)
        .animation(.default, value: viewModel.erro)
        .animation(.default, value: viewModel.aviso)
    }

    // MARK: - Partes

    private var cabecalho: some View {
        VStack(spacing: 10) {
            Image("LogoZenko")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .padding(.top, 32)
            Text("Zenko")
                .font(.largeTitle.bold())
            Text(viewModel.modo == .entrar ? "Entre para continuar" : "Crie sua conta gratuita")
                .foregroundStyle(.secondary)
        }
    }

    private var campoEmail: some View {
        @Bindable var viewModel = viewModel
        return HStack(spacing: 12) {
            Image(systemName: "envelope").foregroundStyle(.secondary).frame(width: 20)
            TextField("E-mail", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($campoFocado, equals: .email)
                .onSubmit { campoFocado = .senha }
                .accessibilityIdentifier("campoEmail")
        }
        .estiloCampo()
    }

    private var campoSenha: some View {
        @Bindable var viewModel = viewModel
        return HStack(spacing: 12) {
            Image(systemName: "lock").foregroundStyle(.secondary).frame(width: 20)
            Group {
                if viewModel.mostrarSenha {
                    TextField("Senha", text: $viewModel.senha)
                } else {
                    SecureField("Senha", text: $viewModel.senha)
                }
            }
            .textContentType(viewModel.modo == .entrar ? .password : .newPassword)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.go)
            .focused($campoFocado, equals: .senha)
            .onSubmit { Task { await viewModel.enviar(auth: auth) } }
            .accessibilityIdentifier("campoSenha")

            Button {
                viewModel.mostrarSenha.toggle()
            } label: {
                Image(systemName: viewModel.mostrarSenha ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel(viewModel.mostrarSenha ? "Esconder senha" : "Mostrar senha")
        }
        .estiloCampo()
    }

    @ViewBuilder
    private var mensagens: some View {
        if let erro = viewModel.erro {
            Label(erro, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("mensagemErro")
        }
        if let aviso = viewModel.aviso {
            Label(aviso, systemImage: "envelope.badge.fill")
                .font(.footnote)
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var separador: some View {
        HStack {
            Rectangle().frame(height: 1).foregroundStyle(.quaternary)
            Text("ou").font(.footnote).foregroundStyle(.secondary)
            Rectangle().frame(height: 1).foregroundStyle(.quaternary)
        }
    }

    private var avisoSemServidor: some View {
        VStack(spacing: 8) {
            Label("Servidor de login ainda não configurado", systemImage: "wrench.and.screwdriver")
                .font(.footnote)
                .foregroundStyle(.secondary)
            #if DEBUG
            Button("Entrar sem servidor (só em desenvolvimento)") {
                auth.entrarModoDesenvolvimento()
            }
            .font(.footnote)
            #endif
        }
    }
}

private extension View {
    func estiloCampo() -> some View {
        padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    LoginView()
        .environment(AuthController())
        .temaZenko()
}
