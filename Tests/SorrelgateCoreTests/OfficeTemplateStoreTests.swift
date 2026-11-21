import Foundation
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
}
