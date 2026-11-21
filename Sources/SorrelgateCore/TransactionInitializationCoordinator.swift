import Foundation

/// The transaction DB persists the complete creation intent atomically with
/// its transaction. The document DB applies it in a separate atomic commit.
/// Restart replay is therefore safe even if the process exits at either edge.
public struct TransactionCreationOutcome: Sendable {
    public let record: TransactionRecord
    public let checklistReady: Bool
    public let warning: String?
}

public struct ChecklistRecoveryReport: Sendable {
    public let completedTransactionIDs: [UUID]
    public let failures: [UUID: String]
}

/// Main-actor serialized entrypoint for manual UI creation and restart recovery.
/// Future LLM callers must use the same guarded domain action, not direct SQL.
@MainActor
public final class TransactionInitializationCoordinator {
    private let service: SorrelgateService
    private let workspace: DocumentWorkspace

    public init(service: SorrelgateService, workspace: DocumentWorkspace) {
        self.service = service
        self.workspace = workspace
    }

    /// Never create the transaction until the exact template (including office
    /// name, revision, requirements and notes) has been captured successfully.
    public func create(
        propertyAddress: String, workflow: WorkflowKind, officeID: UUID?
    ) async throws -> TransactionCreationOutcome {
        let plan = try await workspace.prepareChecklistSeed(
            workflow: workflow, officeID: officeID
        )
        guard case .created(let record) = try service.execute(
            .createTransactionWithChecklist(
                propertyAddress: propertyAddress, workflow: workflow, plan: plan
            )
        ) else { throw SorrelgateError.database("Transaction creation returned no record.") }

        do {
            _ = try await completePendingChecklist(for: record.id)
            return TransactionCreationOutcome(
                record: record, checklistReady: true, warning: nil
            )
        } catch {
            // A committed transaction is NEVER recreated on a checklist failure.
            // The durable intent survives and is automatically retried on restart.
            return TransactionCreationOutcome(
                record: record, checklistReady: false,
                warning: "Transaction saved. Checklist initialization will retry on relaunch: " +
                    error.localizedDescription
            )
        }
    }

    /// Replay and verify a single durable intent, then acknowledge it. No
    /// matching intent means this was an older/manual transaction, not an error.
    @discardableResult
    public func completePendingChecklist(for transactionID: UUID) async throws -> Bool {
        guard case .pendingChecklistIntents(let intents) = try service.execute(
            .pendingChecklistIntents
        ) else { throw SorrelgateError.database("Could not read checklist recovery intents.") }
        guard let intent = intents.first(where: { $0.transactionID == transactionID })
        else { return false }

        _ = try await workspace.applyPreparedChecklistSeed(
            intent.plan, for: transactionID
        )
        guard let source = try await workspace.checklistSnapshot(for: transactionID),
              source.officeID == intent.plan.officeID,
              source.officeName == intent.plan.officeName,
              source.workflow == intent.plan.workflow,
              source.templateVersion == intent.plan.templateVersion
        else {
            // If a manual task exists with no source, do not clobber it or
            // discard the pending intent. Surface an explicit conflict.
            throw OfficeTemplateError.seedConflict
        }
        _ = try service.execute(.acknowledgeChecklistIntent(transactionID))
        return true
    }

    /// Processes every pending record independently so one broken entry cannot
    /// prevent recovery of other transactions. Repeated calls are idempotent.
    public func recoverPending() async throws -> ChecklistRecoveryReport {
        guard case .pendingChecklistIntents(let intents) = try service.execute(
            .pendingChecklistIntents
        ) else { throw SorrelgateError.database("Could not read checklist recovery intents.") }
        var completed: [UUID] = []
        var failures: [UUID: String] = [:]
        for intent in intents {
            do {
                if try await completePendingChecklist(for: intent.transactionID) {
                    completed.append(intent.transactionID)
                }
            } catch {
                failures[intent.transactionID] = error.localizedDescription
            }
        }
        return ChecklistRecoveryReport(
            completedTransactionIDs: completed, failures: failures
        )
    }
}
