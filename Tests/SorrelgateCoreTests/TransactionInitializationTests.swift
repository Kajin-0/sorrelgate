import Foundation
import XCTest
@testable import SorrelgateCore

/// Simulates interruption by closing/reopening both SQLite-backed services at
/// the boundaries where a process may exit. No physical Mac UI is required.
@MainActor
final class TransactionInitializationTests: XCTestCase {
    private func root() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("sorrelgate-recovery-" + UUID().uuidString)
        try FileManager.default.createDirectory(
            at: url, withIntermediateDirectories: true
        )
        return url
    }

    private func service(_ root: URL) throws -> SorrelgateService {
        try SorrelgateService(store: SQLiteTransactionStore(
            fileURL: root.appendingPathComponent("transactions.sqlite")
        ))
    }

    private func documents(_ root: URL) throws -> DocumentWorkspace {
        try DocumentWorkspace(
            databaseURL: root.appendingPathComponent("documents.sqlite"),
            documentsRoot: root.appendingPathComponent("originals")
        )
    }

    private func createPending(
        _ service: SorrelgateService, address: String,
        plan: ChecklistSeedPlan
    ) throws -> UUID {
        guard case .created(let record) = try service.execute(
            .createTransactionWithChecklist(
                propertyAddress: address, workflow: plan.workflow, plan: plan
            )
        ) else { throw SorrelgateError.database("Expected creation receipt") }
        return record.id
    }

    private func pendingIDs(_ service: SorrelgateService) throws -> [UUID] {
        guard case .pendingChecklistIntents(let intents) = try service.execute(
            .pendingChecklistIntents
        ) else { throw SorrelgateError.database("Expected pending intents") }
        return intents.map(\.transactionID)
    }

    func testCrashAfterTransactionCommitReplaysOriginalOfficeRevisionAndMetadata() async throws {
        let dir = try root()
        defer { try? FileManager.default.removeItem(at: dir) }
        let officeID: UUID
        let transactionID: UUID
        do {
            let workspace = try documents(dir)
            let service = try service(dir)
            let office = try await workspace.createOffice(named: "Original Office")
            officeID = office.id
            _ = try await workspace.saveOfficeTemplate(
                officeID: officeID, workflow: .acceptedOffer, expectedVersion: 1,
                tasks: [
                    OfficeTaskSpec(title: "Verify offer", requirement: .required,
                                   notes: "Office-specific review"),
                    OfficeTaskSpec(title: "Welcome seller", requirement: .optional)
                ]
            )
            let original = try await workspace.prepareChecklistSeed(
                workflow: .acceptedOffer, officeID: officeID
            )
            XCTAssertEqual(original.templateVersion, 2)
            // Simulated crash: record and intent are durable, but no document commit.
            transactionID = try createPending(
                service, address: "100 Office Lane", plan: original
            )
            XCTAssertEqual(try pendingIDs(service), [transactionID])
            _ = try await workspace.saveOfficeTemplate(
                officeID: officeID, workflow: .acceptedOffer, expectedVersion: 2,
                tasks: [
                    OfficeTaskSpec(title: "Completely different", requirement: .optional)
                ]
            )
        }
        let service2 = try service(dir)
        let workspace2 = try documents(dir)
        let coordinator = TransactionInitializationCoordinator(
            service: service2, workspace: workspace2
        )
        let ids = try pendingIDs(service2)
        XCTAssertEqual(ids, [transactionID])
        let report = try await coordinator.recoverPending()
        XCTAssertEqual(report.completedTransactionIDs, ids)
        XCTAssertTrue(report.failures.isEmpty)
        XCTAssertTrue(try pendingIDs(service2).isEmpty)
        let rows = try await workspace2.checklist(for: ids[0])
        XCTAssertEqual(rows.map(\.title), ["Verify offer", "Welcome seller"])
        XCTAssertEqual(rows.map(\.requirement), [.required, .optional])
        XCTAssertEqual(rows.first?.notes, "Office-specific review")
        let snapshot = try await workspace2.checklistSnapshot(for: ids[0])
        XCTAssertEqual(snapshot?.officeID, officeID)
        XCTAssertEqual(snapshot?.officeName, "Original Office")
        XCTAssertEqual(snapshot?.templateVersion, 2)
        let repeatReport = try await coordinator.recoverPending()
        XCTAssertTrue(repeatReport.completedTransactionIDs.isEmpty)
        let repeatedRows = try await workspace2.checklist(for: ids[0])
        XCTAssertEqual(repeatedRows, rows)
    }

    func testCrashAfterDocumentCommitBeforeAcknowledgementNeverRewritesEdits() async throws {
        let dir = try root()
        defer { try? FileManager.default.removeItem(at: dir) }
        let id: UUID
        do {
            let workspace = try documents(dir)
            let service = try service(dir)
            let plan = try await workspace.prepareChecklistSeed(
                workflow: .listingPreparation
            )
            id = try createPending(service, address: "88 Local Road", plan: plan)
            let seeded = try await workspace.applyPreparedChecklistSeed(
                plan, for: id
            )
            XCTAssertEqual(seeded, 9)
            let original = try await workspace.checklist(for: id)
            try await workspace.renameTask(
                original[0].id, in: id, to: "Revised by TC"
            )
            try await workspace.updateTask(
                original[0].id, in: id, completed: true
            )
            // Crash here, before acknowledgement removes the outbox record.
        }
        let service2 = try service(dir)
        let workspace2 = try documents(dir)
        let before = try await workspace2.checklist(for: id)
        let coordinator = TransactionInitializationCoordinator(
            service: service2, workspace: workspace2
        )
        let report = try await coordinator.recoverPending()
        XCTAssertEqual(report.completedTransactionIDs, [id])
        XCTAssertTrue(report.failures.isEmpty)
        let after = try await workspace2.checklist(for: id)
        XCTAssertEqual(after, before)
        XCTAssertEqual(after.count, 9)
        XCTAssertEqual(after[0].title, "Revised by TC")
        XCTAssertTrue(after[0].isCompleted)
        XCTAssertTrue(try pendingIDs(service2).isEmpty)
    }

    func testManualChecklistConflictLeavesIntentPendingAndRecoversUnrelatedRecord() async throws {
        let dir = try root()
        defer { try? FileManager.default.removeItem(at: dir) }
        let workspace = try documents(dir)
        let service = try service(dir)
        let plan = try await workspace.prepareChecklistSeed(
            workflow: .acceptedOffer
        )
        let conflicting = try createPending(
            service, address: "Conflict Street", plan: plan
        )
        let normal = try createPending(
            service, address: "Normal Street", plan: plan
        )
        let manual = try await workspace.addTask("Keep manual task", for: conflicting)
        let coordinator = TransactionInitializationCoordinator(
            service: service, workspace: workspace
        )
        let report = try await coordinator.recoverPending()
        XCTAssertEqual(report.completedTransactionIDs, [normal])
        XCTAssertNotNil(report.failures[conflicting])
        XCTAssertEqual(try pendingIDs(service), [conflicting])
        let rows = try await workspace.checklist(for: conflicting)
        XCTAssertEqual(rows.map(\.id), [manual.id])
        let conflictingSource = try await workspace.checklistSnapshot(for: conflicting)
        XCTAssertNil(conflictingSource)
        let normalRows = try await workspace.checklist(for: normal)
        XCTAssertEqual(normalRows.count, 12)
        let second = try await coordinator.recoverPending()
        XCTAssertTrue(second.completedTransactionIDs.isEmpty)
        XCTAssertNotNil(second.failures[conflicting])
    }

    func testCreateReturnsReadyReceiptAndRejectsMissingOfficeWithoutOrphanRecord() async throws {
        let dir = try root()
        defer { try? FileManager.default.removeItem(at: dir) }
        let workspace = try documents(dir)
        let service = try service(dir)
        let coordinator = TransactionInitializationCoordinator(
            service: service, workspace: workspace
        )
        do {
            _ = try await coordinator.create(
                propertyAddress: "123 Example", workflow: .acceptedOffer,
                officeID: UUID()
            )
            XCTFail("Missing office must reject before transaction insert")
        } catch OfficeTemplateError.missingOffice {}
        guard case .transactions(let empty) = try service.execute(.listTransactions)
        else { return XCTFail("Expected transaction list") }
        XCTAssertTrue(empty.isEmpty)

        let created = try await coordinator.create(
            propertyAddress: " 123 Example ", workflow: .acceptedOffer, officeID: nil
        )
        XCTAssertTrue(created.checklistReady)
        XCTAssertNil(created.warning)
        XCTAssertEqual(created.record.propertyAddress, "123 Example")
        XCTAssertEqual(try pendingIDs(service), [])
        let createdTasks = try await workspace.checklist(for: created.record.id)
        XCTAssertEqual(createdTasks.count, 12)
        let createdSource = try await workspace.checklistSnapshot(for: created.record.id)
        XCTAssertEqual(createdSource?.officeName, "Built-in starter")
    }

    func testLegacyTransactionsWithoutIntentsAreNotReinterpreted() async throws {
        let dir = try root()
        defer { try? FileManager.default.removeItem(at: dir) }
        let service = try service(dir)
        let workspace = try documents(dir)
        guard case .created(let legacy) = try service.execute(
            .createTransaction(propertyAddress: "Legacy Address", workflow: .acceptedOffer)
        ) else { return XCTFail("Expected legacy transaction") }
        let coordinator = TransactionInitializationCoordinator(
            service: service, workspace: workspace
        )
        let report = try await coordinator.recoverPending()
        XCTAssertTrue(report.completedTransactionIDs.isEmpty)
        XCTAssertTrue(report.failures.isEmpty)
        let legacySource = try await workspace.checklistSnapshot(for: legacy.id)
        let legacyTasks = try await workspace.checklist(for: legacy.id)
        XCTAssertNil(legacySource)
        XCTAssertTrue(legacyTasks.isEmpty)
        // Legacy/manual loader still works, and is never auto-attributed to an office.
        let seededLegacyCount = try await workspace.seedStarterChecklist(
            for: legacy.id, workflow: .acceptedOffer
        )
        XCTAssertEqual(seededLegacyCount, 12)
    }

    func testAtomicInsertRejectsDuplicateAndDoesNotCreatePartialIntent() async throws {
        let dir = try root()
        defer { try? FileManager.default.removeItem(at: dir) }
        let workspace = try documents(dir)
        let plan = try await workspace.prepareChecklistSeed(workflow: .acceptedOffer)
        let store = try SQLiteTransactionStore(
            fileURL: dir.appendingPathComponent("transactions.sqlite")
        )
        let record = TransactionRecord(
            propertyAddress: "Atomic Avenue", workflow: .acceptedOffer
        )
        try store.insert(record, pendingChecklist: plan)
        XCTAssertThrowsError(try store.insert(record, pendingChecklist: plan))
        XCTAssertEqual(try store.list().map(\.id), [record.id])
        XCTAssertEqual(
            try store.pendingChecklistIntents().map(\.transactionID), [record.id]
        )
        let allTasks = try await workspace.checklist(for: record.id)
        XCTAssertTrue(allTasks.isEmpty)
    }

}
