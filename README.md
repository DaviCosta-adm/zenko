# Zenko

> "O aviso certo, na hora certa."

Zenko é um assistente pessoal para Android que filtra o ruído das notificações do celular, destaca o que realmente importa (financeiro, trabalho, pessoal) e organiza sua rotina com lembretes inteligentes em horários fixos.

Todo dia você recebe dezenas de notificações — e a maioria não importa. O Zenko organiza esse caos automaticamente: identifica o que é relevante (um boleto vencendo, um prazo de trabalho, uma mensagem importante) e destaca isso pra você, enquanto silencia o resto. Ele também aprende com o tempo o que você considera prioridade, ficando mais preciso a cada dia.

---

## ✨ Funcionalidades

- 🔔 **Captura de notificações** do sistema Android via `NotificationListenerService`
- 🧠 **Classificação de importância** por regras locais + IA para casos ambíguos
- ⏰ **Lembretes em horários fixos**, recorrentes, gerenciados via `WorkManager`
- 🔇 **Horário de silêncio** e lista de apps ignorados configuráveis
- 📊 **Painel** com histórico de notificações classificadas por categoria e prioridade

## 🛠️ Stack técnica

| Camada | Tecnologia |
|---|---|
| Linguagem | Kotlin |
| UI | Jetpack Compose |
| Persistência local | Room (SQLite) |
| Background/agendamento | WorkManager |
| Captura de notificações | NotificationListenerService |
| Injeção de dependência | Hilt |
| Assincronismo | Coroutines + Flow |
| Classificação por IA | API Claude |

## 📁 Estrutura do projeto

```
com.usuario.zenko/
├── data/         # entidades Room, DAOs, repositórios, API remota
├── service/      # NotificationCaptureService, ReminderWorker
├── domain/       # ClassifierEngine, NotificationDispatcher, ReminderScheduler
├── ui/           # telas Compose (painel, lembretes, configurações) + navegação
└── di/           # módulos Hilt
```

## 🚀 Roadmap

- [x] Arquitetura técnica definida
- [ ] **Fase 1** — Lembretes em horário fixo (`ReminderScheduler` + `WorkManager`)
- [ ] **Fase 2** — Captura de notificações + painel de histórico
- [ ] **Fase 3** — Motor de classificação com regras + IA
- [ ] **Fase 4** — Tela de configurações (horário de silêncio, apps ignorados, sensibilidade)

## 📋 Pré-requisitos

- Android Studio (versão recente)
- SDK Android 26+ (Android 8.0)
- Permissão de **Acesso a notificações** ativada manualmente pelo usuário em
  `Configurações > Apps > Acesso especial > Acesso a notificações`

## ⚙️ Como rodar

```bash
git clone https://github.com/seu-usuario/zenko.git
cd zenko
```

Abra o projeto no Android Studio, aguarde o Gradle sincronizar e rode em um emulador ou dispositivo físico com Android 8.0+.

## 🤝 Contribuindo

Contribuições são bem-vindas! Para contribuir:

1. Faça um fork do repositório
2. Crie uma branch para sua feature ou correção (`git checkout -b feature/nome-da-feature`)
3. Faça commit das suas alterações (`git commit -m 'Adiciona nome-da-feature'`)
4. Envie para o seu fork (`git push origin feature/nome-da-feature`)
5. Abra um Pull Request descrevendo as mudanças

### Diretrizes

- Siga o estilo de código Kotlin já usado no projeto (nomes de variáveis/funções em português, seguindo o padrão adotado)
- Prefira commits pequenos e descritivos
- Novas funcionalidades devem vir acompanhadas de testes quando possível
- Abra uma *issue* antes de começar mudanças grandes, para alinhar a abordagem

## 🧪 CI/Build

O projeto usa GitHub Actions para build automático a cada push/PR na branch `main` (ver `.github/workflows/android.yml`).

## 📄 Licença

Este projeto está licenciado sob a licença MIT — veja o arquivo [LICENSE](LICENSE) para mais detalhes.
