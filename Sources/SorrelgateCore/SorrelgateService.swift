import Foundation

/// These typed actions are the common entry point for the UI and future
/// permission-controlled LLM tools. No AI access is implemented in M0.
public enum SorrelgateAction: Sendable {
    case createTransaction(propertyAddress: String, workflow: WorkflowKind)
    case createTransactionWithChecklist(
        propertyAddress: String, workflow: WorkflowKind, plan: ChecklistSeedPlan
    )
    case listTransactions
    case pendingChecklistIntents
    case acknowledgeChecklistIntent(UUID)
}

public enum SorrelgateActionResult: Sendable {
    case created(TransactionRecord)
    case transactions([TransactionRecord])
    case pendingChecklistIntents([PendingChecklistIntent])
    case acknowledged
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
        case .createTransactionWithChecklist(let propertyAddress, let workflow, let plan):
            let address = propertyAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !address.isEmpty, address.count <= 250 else {
                throw SorrelgateError.invalidPropertyAddress
            }
            guard plan.workflow == workflow else {
                throw SorrelgateError.database("Checklist workflow does not match transaction.")
            }
            let record = TransactionRecord(propertyAddress: address, workflow: workflow)
            try store.insert(record, pendingChecklist: plan)
            return .created(record)
        case .listTransactions:
            return .transactions(try store.list())
        case .pendingChecklistIntents:
            return .pendingChecklistIntents(try store.pendingChecklistIntents())
        case .acknowledgeChecklistIntent(let id):
            try store.acknowledgeChecklistIntent(transactionID: id)
            return .acknowledged
        }
    }
}
