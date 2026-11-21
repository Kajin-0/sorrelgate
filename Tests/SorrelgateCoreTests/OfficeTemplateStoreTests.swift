import Foundation
import SQLite3
import XCTest
@testable import SorrelgateCore

@MainActor
final class OfficeTemplateStoreTests: XCTestCase {
    private func temporaryRoot() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("sorrelgate-office-" + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        return directory
    }

    private func open(_ root: URL) throws -> DocumentWorkspace {
        try DocumentWorkspace(
            databaseURL: root.appendingPathComponent("documents.sqlite"),
            documentsRoot: root.appendingPathComponent("originals")
        )
    }

    func testTwoOfficesMaintainIndependentTemplates() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let workspace = try open(root)
        let alpha = try await workspace.createOffice(named: "Alpha Realty")
        let beta = try await workspace.createOffice(named: "Beta Brokerage")
        let offices = try await workspace.offices()
        XCTAssertEqual(offices.count, 2)
        let initial = try await workspace.officeTemplate(
            officeID: alpha.id, workflow: .acceptedOffer
        )
        XCTAssertEqual(initial.version, 1)
        XCTAssertEqual(initial.titles.count, 12)
        let changed = try await workspace.saveOfficeTemplate(
            officeID: alpha.id, workflow: .acceptedOffer,
            expectedVersion: 1, titles: ["Alpha first", "Alpha second"]
        )
        XCTAssertEqual(changed.version, 2)
        let originalBeta = try await workspace.officeTemplate(
            officeID: beta.id, workflow: .acceptedOffer
        )
        XCTAssertEqual(originalBeta.version, 1)
        XCTAssertEqual(originalBeta.titles.count, 12)
        let originalOtherWorkflow = try await workspace.officeTemplate(
            officeID: alpha.id, workflow: .listingPreparation
        )
        XCTAssertEqual(originalOtherWorkflow.titles.count, 9)
    }

    func testSnapshotIsImmutableAcrossTemplateChangesAndReopen() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let oldTransaction = UUID()
        let newTransaction = UUID()
        let officeID: UUID
        do {
            let workspace = try open(root)
            let office = try await workspace.createOffice(named: "Pacific Sellers")
            officeID = office.id
            let first = try await workspace.saveOfficeTemplate(
                officeID: officeID, workflow: .acceptedOffer,
                expectedVersion: 1, titles: ["Receive agreement", "Arrange escrow"]
            )
            XCTAssertEqual(first.version, 2)
            let seededOld = try await workspace.seedStarterChecklist(
                for: oldTransaction, workflow: .acceptedOffer, officeID: officeID
            )
            XCTAssertEqual(seededOld, 2)
            _ = try await workspace.saveOfficeTemplate(
                officeID: officeID, workflow: .acceptedOffer,
                expectedVersion: 2, titles: ["New requirement", "Receive agreement"]
            )
            let seededNew = try await workspace.seedStarterChecklist(
                for: newTransaction, workflow: .acceptedOffer, officeID: officeID
            )
            XCTAssertEqual(seededNew, 2)
            // Repeated seeding must not replace previously edited content.
            let seededAgain = try await workspace.seedStarterChecklist(
                for: oldTransaction, workflow: .acceptedOffer, officeID: officeID
            )
            XCTAssertEqual(seededAgain, 0)
        }
        let reopened = try open(root)
        let oldRows = try await reopened.checklist(for: oldTransaction)
        let newRows = try await reopened.checklist(for: newTransaction)
        XCTAssertEqual(oldRows.map(\.title), ["Receive agreement", "Arrange escrow"])
        XCTAssertEqual(newRows.map(\.title), ["New requirement", "Receive agreement"])
        let oldResult = try await reopened.checklistSnapshot(for: oldTransaction)
        let newResult = try await reopened.checklistSnapshot(for: newTransaction)
        let oldSource = try XCTUnwrap(oldResult)
        let newSource = try XCTUnwrap(newResult)
        XCTAssertEqual(oldSource.officeID, officeID)
        XCTAssertEqual(oldSource.officeName, "Pacific Sellers")
        XCTAssertEqual(oldSource.templateVersion, 2)
        XCTAssertEqual(newSource.templateVersion, 3)
    }

    func testManualChecklistCannotBeReplacedByOfficeSelection() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let workspace = try open(root)
        let office = try await workspace.createOffice(named: "Third Office")
        let transaction = UUID()
        let manual = try await workspace.addTask("My custom workflow", for: transaction)
        let count = try await workspace.seedStarterChecklist(
            for: transaction, workflow: .listingPreparation, officeID: office.id
        )
        XCTAssertEqual(count, 0)
        let source = try await workspace.checklistSnapshot(for: transaction)
        XCTAssertNil(source)
        let tasks = try await workspace.checklist(for: transaction)
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.id, manual.id)
        XCTAssertEqual(tasks.first?.title, "My custom workflow")
    }

    func testOptimisticVersionAndInvalidInputRejectWithoutMutation() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let workspace = try open(root)
        let office = try await workspace.createOffice(named: "Secure Office")
        let first = try await workspace.officeTemplate(
            officeID: office.id, workflow: .acceptedOffer
        )
        do {
            _ = try await workspace.createOffice(named: "secure OFFICE")
            XCTFail("Case-insensitive duplicate office was accepted")
        } catch OfficeTemplateError.duplicateOfficeName {}
        do {
            _ = try await workspace.saveOfficeTemplate(
                officeID: office.id, workflow: .acceptedOffer,
                expectedVersion: 0, titles: ["Unsafe change"]
            )
            XCTFail("Stale template mutation succeeded")
        } catch OfficeTemplateError.staleTemplate {}
        do {
            _ = try await workspace.saveOfficeTemplate(
                officeID: office.id, workflow: .acceptedOffer,
                expectedVersion: 1, titles: ["Same", "same"]
            )
            XCTFail("Duplicate task labels were accepted")
        } catch OfficeTemplateError.invalidTasks {}
        do {
            _ = try await workspace.seedStarterChecklist(
                for: UUID(), workflow: .acceptedOffer, officeID: UUID()
            )
            XCTFail("Missing office was accepted")
        } catch OfficeTemplateError.missingOffice {}
        let current = try await workspace.officeTemplate(
            officeID: office.id, workflow: .acceptedOffer
        )
        XCTAssertEqual(current, first)
    }

    func testStarterSnapshotSourceAndTransactionTaskEditSurviveReopen() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let transaction = UUID()
        do {
            let workspace = try open(root)
            let seeded = try await workspace.seedStarterChecklist(
                for: transaction, workflow: .listingPreparation
            )
            XCTAssertEqual(seeded, 9)
            let rows = try await workspace.checklist(for: transaction)
            try await workspace.renameTask(
                rows[0].id, in: transaction, to: "TC-adjusted listing task"
            )
        }
        let reopened = try open(root)
        let rows = try await reopened.checklist(for: transaction)
        XCTAssertEqual(rows.count, 9)
        XCTAssertEqual(rows[0].title, "TC-adjusted listing task")
        let storedSource = try await reopened.checklistSnapshot(for: transaction)
        let source = try XCTUnwrap(storedSource)
        XCTAssertNil(source.officeID)
        XCTAssertEqual(source.officeName, "Built-in starter")
        XCTAssertEqual(source.templateVersion, 1)
        let second = try await reopened.seedStarterChecklist(
            for: transaction, workflow: .listingPreparation
        )
        XCTAssertEqual(second, 0)
    }
    func testRichMetadataSurvivesVersionedSnapshotsAndReopen() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let oldID = UUID()
        let newID = UUID()
        let officeID: UUID
        do {
            let workspace = try open(root)
            let office = try await workspace.createOffice(named: "Metadata Office")
            officeID = office.id
            let first = try await workspace.saveOfficeTemplate(
                officeID: officeID, workflow: .acceptedOffer, expectedVersion: 1,
                tasks: [
                    OfficeTaskSpec(title: "Obtain paperwork", requirement: .required,
                                   notes: "Requested by office"),
                    OfficeTaskSpec(title: "Send introduction", requirement: .optional)
                ]
            )
            XCTAssertEqual(first.version, 2)
            _ = try await workspace.seedStarterChecklist(
                for: oldID, workflow: .acceptedOffer, officeID: officeID
            )
            let second = try await workspace.saveOfficeTemplate(
                officeID: officeID, workflow: .acceptedOffer, expectedVersion: 2,
                tasks: [
                    OfficeTaskSpec(title: "Obtain paperwork", requirement: .optional,
                                   notes: "Revised office guidance"),
                    OfficeTaskSpec(title: "Send introduction", requirement: .optional)
                ]
            )
            XCTAssertEqual(second.version, 3)
            _ = try await workspace.seedStarterChecklist(
                for: newID, workflow: .acceptedOffer, officeID: officeID
            )
        }
        let reopened = try open(root)
        let oldRows = try await reopened.checklist(for: oldID)
        let newRows = try await reopened.checklist(for: newID)
        XCTAssertEqual(oldRows.first?.requirement, .required)
        XCTAssertEqual(oldRows.first?.notes, "Requested by office")
        XCTAssertEqual(newRows.first?.requirement, .optional)
        XCTAssertEqual(newRows.first?.notes, "Revised office guidance")
        let oldSource = try await reopened.checklistSnapshot(for: oldID)
        let newSource = try await reopened.checklistSnapshot(for: newID)
        XCTAssertEqual(oldSource?.templateVersion, 2)
        XCTAssertEqual(newSource?.templateVersion, 3)
        let repeatSeed = try await reopened.seedStarterChecklist(
            for: oldID, workflow: .acceptedOffer, officeID: officeID
        )
        XCTAssertEqual(repeatSeed, 0)
        let preservedOld = try await reopened.checklist(for: oldID)
        XCTAssertEqual(preservedOld, oldRows)
    }

    func testMetadataOnlyRevisionAndLegacyTitleSavePreserveRequirements() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let workspace = try open(root)
        let office = try await workspace.createOffice(named: "Notes Office")
        let original = try await workspace.officeTemplate(
            officeID: office.id, workflow: .listingPreparation
        )
        var tasks = original.tasks
        tasks[0].requirement = .required
        tasks[0].notes = "Office configured, not a legal finding"
        let changed = try await workspace.saveOfficeTemplate(
            officeID: office.id, workflow: .listingPreparation,
            expectedVersion: original.version, tasks: tasks
        )
        XCTAssertEqual(changed.version, 2)
        XCTAssertEqual(changed.titles, original.titles)
        XCTAssertEqual(changed.tasks[0].requirement, .required)
        do {
            var invalid = changed.tasks
            invalid[0].notes = String(repeating: "n", count: 501)
            _ = try await workspace.saveOfficeTemplate(
                officeID: office.id, workflow: .listingPreparation,
                expectedVersion: 2, tasks: invalid
            )
            XCTFail("Oversized notes accepted")
        } catch OfficeTemplateError.invalidTasks {}
        let same = try await workspace.saveOfficeTemplate(
            officeID: office.id, workflow: .listingPreparation,
            expectedVersion: 2, titles: changed.titles
        )
        XCTAssertEqual(same.version, 2)
        XCTAssertEqual(same.tasks, changed.tasks)
    }

    func testLegacyDatabaseMigratesExistingRowsWithoutChangingCompletion() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("documents.sqlite")
        let transactionID = UUID()
        let checklistID = UUID()
        let officeID = UUID()
        var database: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &database), SQLITE_OK)
        let legacySQL = """
            CREATE TABLE checklist_tasks (
                id TEXT PRIMARY KEY NOT NULL,
                transaction_id TEXT NOT NULL,
                title TEXT NOT NULL,
                completed INTEGER NOT NULL DEFAULT 0,
                linked_document_id TEXT
            );
            INSERT INTO checklist_tasks(id,transaction_id,title,completed)
            VALUES ('\(checklistID.uuidString)','\(transactionID.uuidString)','Old task',1);
            CREATE TABLE office_profiles (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL COLLATE NOCASE UNIQUE,
                created_at REAL NOT NULL
            );
            CREATE TABLE office_template_versions (
                office_id TEXT NOT NULL, workflow TEXT NOT NULL,
                version INTEGER NOT NULL, created_at REAL NOT NULL,
                PRIMARY KEY (office_id,workflow,version)
            );
            CREATE TABLE office_template_rows (
                office_id TEXT NOT NULL, workflow TEXT NOT NULL,
                version INTEGER NOT NULL, ordinal INTEGER NOT NULL,
                title TEXT NOT NULL,
                PRIMARY KEY (office_id,workflow,version,ordinal)
            );
            INSERT INTO office_profiles(id,name,created_at)
            VALUES ('\(officeID.uuidString)','Legacy Office',0);
            INSERT INTO office_template_versions(office_id,workflow,version,created_at)
            VALUES ('\(officeID.uuidString)','acceptedOffer',1,0);
            INSERT INTO office_template_rows(office_id,workflow,version,ordinal,title)
            VALUES ('\(officeID.uuidString)','acceptedOffer',1,0,'Old office requirement');
            """
        XCTAssertEqual(sqlite3_exec(database, legacySQL, nil, nil, nil), SQLITE_OK)
        XCTAssertEqual(sqlite3_close(database), SQLITE_OK)
        let workspace = try open(root)
        let rows = try await workspace.checklist(for: transactionID)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].id, checklistID)
        XCTAssertTrue(rows[0].isCompleted)
        XCTAssertEqual(rows[0].requirement, .unspecified)
        XCTAssertEqual(rows[0].notes, "")
        let template = try await workspace.officeTemplate(
            officeID: officeID, workflow: .acceptedOffer
        )
        XCTAssertEqual(template.version, 1)
        XCTAssertEqual(template.tasks, [OfficeTaskSpec(title: "Old office requirement")])
        let secondOpen = try open(root)
        let reread = try await secondOpen.checklist(for: transactionID)
        XCTAssertEqual(reread, rows)
    }

}
