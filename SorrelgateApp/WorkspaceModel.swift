import Foundation
import SorrelgateCore

@MainActor
final class WorkspaceModel: ObservableObject {
    @Published private(set) var transactions: [TransactionRecord] = []
    @Published var selectedTransactionID: UUID?
    @Published var errorMessage: String?

    private var service: SorrelgateService?

    init() {
        do {
            let directory = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0].appendingPathComponent("Sorrelgate", isDirectory: true)
            let store = try SQLiteTransactionStore(
                fileURL: directory.appendingPathComponent("transactions.sqlite")
            )
            service = SorrelgateService(store: store)
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() {
        guard let service else { return }
        do {
            guard case .transactions(let records) = try service.execute(.listTransactions) else {
                return
            }
            transactions = records
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(address: String, workflow: WorkflowKind) -> Bool {
        guard let service else {
            errorMessage = "The local database is unavailable."
            return false
        }
        do {
            guard case .created(let transaction) = try service.execute(
                .createTransaction(propertyAddress: address, workflow: workflow)
            ) else {
                return false
            }
            refresh()
            selectedTransactionID = transaction.id
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
