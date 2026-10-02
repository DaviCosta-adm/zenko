# Arquitetura Zenko — Versão iOS

Swift · SwiftUI

---

## 1. Visão geral (versão realista para iOS)

O iOS não permite capturar notificações de outros apps do sistema — não existe API pública equivalente ao `NotificationListenerService` do Android. Por isso, o Zenko no iOS muda de conceito: em vez de "escutar tudo que aparece na tela", ele vira um **assistente de itens que você registra ou conecta por integração oficial**, e cuida de destacar o que importa e lembrar você na hora certa.

O que se mantém da ideia original:
- Classificação de importância (regras + IA)
- Lembretes em horários fixos
- Painel organizado por prioridade/categoria
- Horário de silêncio e preferências

O que muda:
- Não há captura automática de notificações do sistema
- Itens entram no Zenko de duas formas: **manual** (usuário adiciona) ou **integração via API oficial** (ex: Calendário do iOS via EventKit)

---

## 2. Stack técnica

| Camada | Tecnologia | Motivo |
|---|---|---|
| Linguagem | Swift | Padrão oficial Apple |
| UI | SwiftUI | Mesmo padrão usado no Aurea |
| Persistência local | SwiftData | Padrão moderno Apple (substitui Core Data), integra bem com SwiftUI |
| Agendamento de lembretes | UserNotifications (`UNUserNotificationCenter`) | API nativa para notificações locais agendadas |
| Integração com Calendário | EventKit | API pública da Apple para ler eventos do Calendário/Lembretes do sistema |
| Classificação por IA | Chamada HTTP à API Claude | Mesmo padrão do Aurea |
| Assincronismo | Swift Concurrency (`async/await`) | Padrão moderno Swift |

---

## 3. Estrutura de pastas

```
Zenko/
├── Models/
│   ├── ItemRegistrado.swift
│   ├── Lembrete.swift
│   ├── RegraClassificacao.swift
│   └── PreferenciaUsuario.swift
├── Services/
│   ├── ClassifierEngine.swift
│   ├── ReminderScheduler.swift
│   ├── CalendarioIntegracao.swift   // EventKit
│   └── ClassificadorAPI.swift        // chamada à IA
├── Repositories/
│   ├── ItemRepository.swift
│   ├── LembreteRepository.swift
│   └── PreferenciaRepository.swift
├── Views/
│   ├── Painel/
│   │   ├── PainelView.swift
│   │   └── PainelViewModel.swift
│   ├── Lembretes/
│   │   ├── LembretesView.swift
│   │   └── LembretesViewModel.swift
│   └── Configuracoes/
│       ├── ConfiguracoesView.swift
│       └── ConfiguracoesViewModel.swift
├── ZenkoApp.swift
└── Info.plist
```

---

## 4. Permissões (Info.plist)

```xml
<key>NSUserNotificationsUsageDescription</key>
<string>O Zenko precisa enviar notificações para te avisar sobre itens importantes e lembretes.</string>

<key>NSCalendarsUsageDescription</key>
<string>O Zenko usa seu Calendário para identificar compromissos importantes e organizá-los por prioridade.</string>
```

> Diferente do Android, aqui as permissões são pedidas via diálogo padrão do sistema (`requestAuthorization`), sem precisar guiar o usuário até uma tela de configurações manualmente.

---

## 5. Modelos de dados (SwiftData)

```swift
// Models/ItemRegistrado.swift
import SwiftData

@Model
class ItemRegistrado {
    var titulo: String
    var conteudo: String
    var origem: String            // "manual", "calendario"
    var timestamp: Date
    var pontuacaoImportancia: Int // 0-100
    var categoria: String         // "financeiro", "trabalho", "pessoal", "outro"
    var lido: Bool

    init(titulo: String, conteudo: String, origem: String, pontuacaoImportancia: Int, categoria: String) {
        self.titulo = titulo
        self.conteudo = conteudo
        self.origem = origem
        self.timestamp = Date()
        self.pontuacaoImportancia = pontuacaoImportancia
        self.categoria = categoria
        self.lido = false
    }
}

// Models/Lembrete.swift
@Model
class Lembrete {
    var titulo: String
    var descricao: String?
    var horario: DateComponents   // hora e minuto
    var diasSemana: [Int]         // 1 = domingo ... 7 = sábado
    var ativo: Bool

    init(titulo: String, descricao: String? = nil, horario: DateComponents, diasSemana: [Int]) {
        self.titulo = titulo
        self.descricao = descricao
        self.horario = horario
        self.diasSemana = diasSemana
        self.ativo = true
    }
}

// Models/RegraClassificacao.swift
@Model
class RegraClassificacao {
    var tipo: String       // "palavraChave" ou "origem"
    var valor: String
    var pesoAtribuido: Int // -50 a +50

    init(tipo: String, valor: String, pesoAtribuido: Int) {
        self.tipo = tipo
        self.valor = valor
        self.pesoAtribuido = pesoAtribuido
    }
}

// Models/PreferenciaUsuario.swift
@Model
class PreferenciaUsuario {
    var horarioSilencioInicio: DateComponents
    var horarioSilencioFim: DateComponents
    var sensibilidadeIA: Int // 0-100

    init(horarioSilencioInicio: DateComponents, horarioSilencioFim: DateComponents, sensibilidadeIA: Int = 50) {
        self.horarioSilencioInicio = horarioSilencioInicio
        self.horarioSilencioFim = horarioSilencioFim
        self.sensibilidadeIA = sensibilidadeIA
    }
}
```

---

## 6. ClassifierEngine

```swift
// Services/ClassifierEngine.swift
struct ResultadoClassificacao {
    let pontuacao: Int
    let categoria: String
}

class ClassifierEngine {
    private let classificadorAPI: ClassificadorAPI

    init(classificadorAPI: ClassificadorAPI) {
        self.classificadorAPI = classificadorAPI
    }

    func classificar(
        titulo: String,
        conteudo: String,
        origem: String,
        regras: [RegraClassificacao],
        preferencias: PreferenciaUsuario
    ) async -> ResultadoClassificacao {

        // 1) regras locais
        var pontuacaoBase = 50
        for regra in regras {
            let bateu = regra.tipo == "origem"
                ? origem.localizedCaseInsensitiveContains(regra.valor)
                : (conteudo.localizedCaseInsensitiveContains(regra.valor) ||
                   titulo.localizedCaseInsensitiveContains(regra.valor))
            if bateu { pontuacaoBase += regra.pesoAtribuido }
        }
        pontuacaoBase = min(max(pontuacaoBase, 0), 100)

        // 2) só chama IA se estiver na zona ambígua
        let zonaAmbigua = (preferencias.sensibilidadeIA - 15)...(preferencias.sensibilidadeIA + 15)
        guard zonaAmbigua.contains(pontuacaoBase) else {
            return ResultadoClassificacao(pontuacao: pontuacaoBase, categoria: categorizarPorPalavras(conteudo))
        }

        do {
            return try await classificadorAPI.classificarComIA(titulo: titulo, conteudo: conteudo, origem: origem)
        } catch {
            return ResultadoClassificacao(pontuacao: pontuacaoBase, categoria: categorizarPorPalavras(conteudo))
        }
    }

    private func categorizarPorPalavras(_ conteudo: String) -> String {
        if conteudo.range(of: "pix|boleto|fatura|cartão", options: .regularExpression) != nil {
            return "financeiro"
        } else if conteudo.range(of: "reunião|prazo|entrega|projeto", options: .regularExpression) != nil {
            return "trabalho"
        }
        return "pessoal"
    }
}
```

```swift
// Services/ClassificadorAPI.swift
class ClassificadorAPI {
    func classificarComIA(titulo: String, conteudo: String, origem: String) async throws -> ResultadoClassificacao {
        let prompt = """
        Classifique o item abaixo em JSON puro, sem texto extra:
        {"pontuacao": 0-100, "categoria": "financeiro|trabalho|pessoal|outro"}

        Origem: \(origem)
        Título: \(titulo)
        Conteúdo: \(conteudo)
        """

        // chamada HTTP à API Claude (mesmo padrão usado no Aurea)
        let respostaJSON = try await enviarParaClaude(prompt: prompt)
        return try parseResultado(respostaJSON)
    }

    private func enviarParaClaude(prompt: String) async throws -> String {
        // implementação da chamada HTTP (URLSession) aqui
        fatalError("implementar chamada HTTP")
    }

    private func parseResultado(_ json: String) throws -> ResultadoClassificacao {
        let limpo = json
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        struct Resposta: Codable { let pontuacao: Int; let categoria: String }
        let data = limpo.data(using: .utf8)!
        let resposta = try JSONDecoder().decode(Resposta.self, from: data)
        return ResultadoClassificacao(pontuacao: resposta.pontuacao, categoria: resposta.categoria)
    }
}
```

---

## 7. ReminderScheduler (UserNotifications)

```swift
// Services/ReminderScheduler.swift
import UserNotifications

class ReminderScheduler {

    func solicitarPermissao() async -> Bool {
        let centro = UNUserNotificationCenter.current()
        return (try? await centro.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func agendar(_ lembrete: Lembrete) {
        let conteudo = UNMutableNotificationContent()
        conteudo.title = "⏰ \(lembrete.titulo)"
        conteudo.body = lembrete.descricao ?? ""
        conteudo.sound = .default

        for dia in lembrete.diasSemana {
            var componentes = lembrete.horario
            componentes.weekday = dia

            let trigger = UNCalendarNotificationTrigger(dateMatching: componentes, repeats: true)
            let identificador = "lembrete_\(lembrete.persistentModelID)_\(dia)"
            let request = UNNotificationRequest(identifier: identificador, content: conteudo, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelar(_ lembrete: Lembrete) {
        let identificadores = lembrete.diasSemana.map { "lembrete_\(lembrete.persistentModelID)_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identificadores)
    }
}
```

---

## 8. Integração com Calendário (EventKit)

```swift
// Services/CalendarioIntegracao.swift
import EventKit

class CalendarioIntegracao {
    private let store = EKEventStore()

    func solicitarAcesso() async -> Bool {
        (try? await store.requestFullAccessToEvents()) ?? false
    }

    func buscarEventosProximos(dias: Int = 7) -> [EKEvent] {
        let inicio = Date()
        let fim = Calendar.current.date(byAdding: .day, value: dias, to: inicio)!
        let predicate = store.predicateForEvents(withStart: inicio, end: fim, calendars: nil)
        return store.events(matching: predicate)
    }
}
```

Esses eventos são convertidos em `ItemRegistrado` (origem `"calendario"`) e passam pelo mesmo `ClassifierEngine`.

---

## 9. Repositórios

```swift
// Repositories/ItemRepository.swift
import SwiftData

@MainActor
class ItemRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func salvar(_ item: ItemRegistrado) {
        context.insert(item)
        try? context.save()
    }

    func listarTodos() -> [ItemRegistrado] {
        (try? context.fetch(FetchDescriptor<ItemRegistrado>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        ))) ?? []
    }
}

// Repositories/LembreteRepository.swift
@MainActor
class LembreteRepository {
    private let context: ModelContext
    private let scheduler: ReminderScheduler

    init(context: ModelContext, scheduler: ReminderScheduler) {
        self.context = context
        self.scheduler = scheduler
    }

    func criar(_ lembrete: Lembrete) {
        context.insert(lembrete)
        try? context.save()
        scheduler.agendar(lembrete)
    }

    func remover(_ lembrete: Lembrete) {
        scheduler.cancelar(lembrete)
        context.delete(lembrete)
        try? context.save()
    }
}
```

---

## 10. Telas (SwiftUI — esqueleto)

```swift
// Views/Painel/PainelView.swift
import SwiftUI
import SwiftData

struct PainelView: View {
    @Query(sort: \ItemRegistrado.timestamp, order: .reverse) var itens: [ItemRegistrado]

    var body: some View {
        NavigationStack {
            List(itens) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.titulo).font(.headline)
                        Spacer()
                        Text("\(item.pontuacaoImportancia)%")
                            .foregroundStyle(cor(para: item.pontuacaoImportancia))
                    }
                    Text(item.conteudo).font(.subheadline).lineLimit(2)
                    Text(item.categoria).font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Zenko")
        }
    }

    func cor(para pontuacao: Int) -> Color {
        switch pontuacao {
        case 70...: return .red
        case 40..<70: return .orange
        default: return .gray
        }
    }
}
```

`LembretesView` e `ConfiguracoesView` seguem o mesmo padrão do Aurea: `@Query`/`@State` observando o SwiftData, formulários com `TextField`, `DatePicker` e `Toggle` para CRUD de lembretes e ajuste de preferências.

---

## 11. Fluxo de dados resumido

```
Usuário adiciona item manualmente  OU  CalendarioIntegracao busca eventos (EventKit)
        │
        ▼
ClassifierEngine.classificar()  ──► regras locais ──► (ambíguo?) ──► ClassificadorAPI (IA)
        │
        ▼
ItemRepository.salvar()  (grava no SwiftData)
        │
        ▼
PainelView observa via @Query e atualiza a UI automaticamente
```

Em paralelo, `ReminderScheduler` agenda notificações locais via `UNUserNotificationCenter`, que disparam mesmo com o app fechado — isso é nativo do iOS e não exige nenhum serviço em segundo plano.

---

## 12. Próximos passos práticos

1. Criar o projeto no Xcode com SwiftData e SwiftUI (mesma base do Aurea)
2. Implementar Fase 1: `Lembrete` + `ReminderScheduler` + `LembretesView` (testável de imediato)
3. Implementar Fase 2: `ItemRegistrado` + tela de adicionar item manual + `PainelView`
4. Implementar Fase 3: `ClassifierEngine` com regras, depois IA
5. Implementar Fase 4: `CalendarioIntegracao` (EventKit)
6. Por último: `ConfiguracoesView` completa
