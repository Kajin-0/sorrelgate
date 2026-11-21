import Foundation
import XCTest
@testable import SorrelgateCore

final class CSVChecklistImporterTests: XCTestCase {
    func testQuotedCommasAndEscapedQuotesWithSelectedColumn() throws {
        let csv = "\u{FEFF}Phase,Task,Notes\r\n" +
            "One,\"Collect offer, signed\",A\r\n" +
            "Two,\"Review \"\"accepted\"\" contract\",B\r\n"
        let table = try CSVChecklistImporter.parse(Data(csv.utf8))
        XCTAssertEqual(table.headers, ["Phase", "Task", "Notes"])
        XCTAssertEqual(table.rows.count, 2)
        let review = try CSVChecklistImporter.review(table, titleColumn: 1)
        XCTAssertTrue(review.issues.isEmpty)
        XCTAssertEqual(review.titles, [
            "Collect offer, signed", "Review \"accepted\" contract"
        ])
    }

    func testEmbeddedNewlineRejectedInTaskWithoutDroppingRow() throws {
        let csv = "Task,Other\r\n\"First line\nsecond line\",A\r\n" +
            "Good task,B\r\n"
        let table = try CSVChecklistImporter.parse(Data(csv.utf8))
        XCTAssertEqual(table.rows.count, 2)
        let review = try CSVChecklistImporter.review(table, titleColumn: 0)
        XCTAssertEqual(review.titles, ["Good task"])
        XCTAssertEqual(review.issues.count, 1)
        XCTAssertEqual(review.issues[0].sourceLine, 2)
    }

    func testReviewFindsUnmatchedRowsAndDuplicates() throws {
        let csv = "Item,Workflow,Notes\n" +
            "Receive agreement,Accepted,One\n" +
            "receive AGREEMENT,Accepted,Duplicate\n" +
            ",Accepted,Blank\n" +
            "Wrong number,Accepted\n"
        let table = try CSVChecklistImporter.parse(Data(csv.utf8))
        let review = try CSVChecklistImporter.review(table, titleColumn: 0)
        XCTAssertEqual(review.titles, ["Receive agreement"])
        XCTAssertEqual(review.issues.count, 3)
        XCTAssertEqual(review.issues.map(\.sourceLine), [3, 4, 5])
        XCTAssertThrowsError(try CSVChecklistImporter.review(table, titleColumn: 6))
    }

    func testMalformedQuotesOversizeAndEmptyReject() throws {
        XCTAssertThrowsError(try CSVChecklistImporter.parse(Data("Task\n\"Unclosed".utf8)))
        XCTAssertThrowsError(try CSVChecklistImporter.parse(Data("Task\n\"ok\"oops".utf8)))
        XCTAssertThrowsError(try CSVChecklistImporter.parse(Data("Task\n".utf8)))
        let huge = Data(repeating: 65, count: CSVChecklistImporter.byteLimit + 1)
        XCTAssertThrowsError(try CSVChecklistImporter.parse(huge))
        XCTAssertThrowsError(try CSVChecklistImporter.parse(Data([0xFF, 0xFE, 0x00])))
    }
    func testExplicitMetadataMappingAndPhysicalCSVLineProvenance() throws {
        let source = "Phase,Notes,Required?,Task\r\n" +
            "First,\"Call seller,\nconfirm dates\",Yes,Collect agreement\r\n" +
            "Second,Verify originals,No,Review disclosures\r\n" +
            "Third,, ,Confirm receipt\r\n"
        let table = try CSVChecklistImporter.parse(Data(source.utf8))
        XCTAssertEqual(table.rows.map(\.sourceLine), [2, 4, 5])
        let review = try CSVChecklistImporter.review(
            table, mapping: CSVChecklistMapping(
                titleColumn: 3, requirementColumn: 2, notesColumn: 1
            )
        )
        XCTAssertTrue(review.issues.isEmpty)
        XCTAssertEqual(review.titles, [
            "Collect agreement", "Review disclosures", "Confirm receipt"
        ])
        XCTAssertEqual(review.tasks.map(\.requirement), [
            .required, .optional, .unspecified
        ])
        XCTAssertEqual(review.tasks.map(\.notes), [
            "Call seller,\nconfirm dates", "Verify originals", ""
        ])
    }

    func testInvalidRequirementsOversizedNotesAndDuplicatesBlockApproval() throws {
        let tooLong = String(repeating: "x", count: 501)
        let source = "Task,Office required,Notes\n" +
            "Inspect agreement,Maybe,ok\n" +
            "Prepare disclosure,Required,\(tooLong)\n" +
            "inspect AGREEMENT,No,ok\n"
        let table = try CSVChecklistImporter.parse(Data(source.utf8))
        let review = try CSVChecklistImporter.review(
            table, mapping: CSVChecklistMapping(
                titleColumn: 0, requirementColumn: 1, notesColumn: 2
            )
        )
        XCTAssertEqual(review.issues.map(\.sourceLine), [2, 3, 4])
        XCTAssertEqual(review.tasks.count, 0)
        XCTAssertTrue(review.issues[0].detail.contains("Unrecognized"))
        XCTAssertTrue(review.issues[1].detail.contains("500"))
        XCTAssertTrue(review.issues[2].detail.contains("Duplicate"))
    }

    func testTitleOnlyDoesNotInferMetadataAndConflictingMappingsRefuse() throws {
        let table = try CSVChecklistImporter.parse(Data(
            "Task,Requirement,Notes\nReview offer,Required,Get confirmation\n".utf8
        ))
        let original = try CSVChecklistImporter.review(table, titleColumn: 0)
        XCTAssertTrue(original.issues.isEmpty)
        XCTAssertEqual(original.tasks.count, 1)
        XCTAssertEqual(original.tasks[0].requirement, .unspecified)
        XCTAssertEqual(original.tasks[0].notes, "")
        XCTAssertThrowsError(try CSVChecklistImporter.review(
            table, mapping: CSVChecklistMapping(titleColumn: 0, requirementColumn: 0)
        ))
        XCTAssertThrowsError(try CSVChecklistImporter.review(
            table, mapping: CSVChecklistMapping(titleColumn: 0, notesColumn: 4)
        ))
        let explicit = try CSVChecklistImporter.review(
            table, mapping: CSVChecklistMapping(
                titleColumn: 0, requirementColumn: 1, notesColumn: 2
            )
        )
        XCTAssertEqual(explicit.tasks[0].requirement, .required)
        XCTAssertEqual(explicit.tasks[0].notes, "Get confirmation")
    }

    @MainActor
    func testReviewedSpreadsheetTasksOnlyPersistAfterExplicitOfficeSave() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sorrelgate-mapping-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let workspace = try DocumentWorkspace(
            databaseURL: root.appendingPathComponent("documents.sqlite"),
            documentsRoot: root.appendingPathComponent("originals")
        )
        let office = try await workspace.createOffice(named: "Mapped Office")
        let source = try CSVChecklistImporter.parse(Data(
            "Notes,Title,Required\nConfirm with owner,Collect offer,Yes\n,Send update,No\n".utf8
        ))
        let review = try CSVChecklistImporter.review(
            source, mapping: CSVChecklistMapping(
                titleColumn: 1, requirementColumn: 2, notesColumn: 0
            )
        )
        XCTAssertTrue(review.issues.isEmpty)
        let unchanged = try await workspace.officeTemplate(
            officeID: office.id, workflow: .acceptedOffer
        )
        XCTAssertEqual(unchanged.version, 1)
        XCTAssertEqual(unchanged.tasks.count, 12)
        let saved = try await workspace.saveOfficeTemplate(
            officeID: office.id, workflow: .acceptedOffer,
            expectedVersion: 1, tasks: review.tasks
        )
        XCTAssertEqual(saved.version, 2)
        let transaction = UUID()
        _ = try await workspace.seedStarterChecklist(
            for: transaction, workflow: .acceptedOffer, officeID: office.id
        )
        let persisted = try await workspace.checklist(for: transaction)
        XCTAssertEqual(persisted.map(\.title), review.titles)
        XCTAssertEqual(persisted.map(\.requirement), [.required, .optional])
        XCTAssertEqual(persisted.map(\.notes), ["Confirm with owner", ""])
        _ = try await workspace.saveOfficeTemplate(
            officeID: office.id, workflow: .acceptedOffer,
            expectedVersion: 2, tasks: [
                OfficeTaskSpec(title: "Different office revision", requirement: .optional)
            ]
        )
        let historical = try await workspace.checklist(for: transaction)
        XCTAssertEqual(historical, persisted)
    }

}
