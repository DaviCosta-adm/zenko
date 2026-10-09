import Foundation
import SwiftData

@MainActor
final class ItemRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func salvar(_ item: ItemRegistrado) {
        context.insert(item)
        try? context.save()
    }

    func remover(_ item: ItemRegistrado) {
        context.delete(item)
        try? context.save()
    }

    func marcarComoLido(_ item: ItemRegistrado) {
        item.lido = true
        try? context.save()
    }

    func alternarLido(_ item: ItemRegistrado) {
        item.lido.toggle()
        try? context.save()
    }

    func listarTodos() -> [ItemRegistrado] {
        (try? context.fetch(FetchDescriptor<ItemRegistrado>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        ))) ?? []
    }

    func existe(idExterno: String) -> Bool {
        let descritor = FetchDescriptor<ItemRegistrado>(
            predicate: #Predicate { $0.idExterno == idExterno }
        )
        return ((try? context.fetchCount(descritor)) ?? 0) > 0
    }
}
