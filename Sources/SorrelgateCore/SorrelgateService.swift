import Foundation

/// These typed actions are the common entry point for the UI and future
/// permission-controlled LLM tools. No AI access is implemented in M0.
public enum SorrelgateAction: Sendable {
    case createTransaction(propertyAddress: String, workflow: WorkflowKind)
    case listTransactions
}

public enum SorrelgateActionResult: Sendable {
    case created(TransactionRecord)
    case transactions([TransactionRecord])
}

public final class SorrelgateService {
    private let store: SQLiteTransactionStore

    public init(store: SQLiteTransactionStore) {
        self.store = store
    }

    @discardableResult
    public func execute(_ action: SorrelgateAction) throws -> SorrelgateActionResult {
        switch action {
        case .createTransaction(let propertyAddress, let workflow):
            let address = propertyAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !address.isEmpty, address.count <= 250 else {
                throw SorrelgateError.invalidPropertyAddress
            }
            let record = TransactionRecord(propertyAddress: address, workflow: workflow)
            try store.insert(record)
            return .created(record)
        case .listTransactions:
            return .transactions(try store.list())
        }
    }
}
