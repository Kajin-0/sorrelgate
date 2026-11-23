import AppKit
import CoreGraphics
import CoreText
import Foundation
import PDFKit
import XCTest
@testable import SorrelgateCore

/// One end-to-end, fictional transaction on actual SQLite + PDFKit.
// Red flag: not a macOS Ventura GUI test; this catches backend integration regressions.
@MainActor
final class PilotJourneyTests: XCTestCase {
    private func root() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SorrelgatePilotJourney-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// A tiny real PDF fixture; each string becomes selectable text on one page.
    private func makePDF(_ url: URL, pages: [String]) throws {
        guard let consumer = CGDataConsumer(url: url as CFURL) else {
            throw NSError(domain: "PilotFixture", code: 1)
        }
        var media = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let context = CGContext(consumer: consumer, mediaBox: &media, nil) else {
            throw NSError(domain: "PilotFixture", code: 2)
        }
        let font = CTFontCreateWithName("Helvetica" as CFString, 22, nil)
        for page in pages {
            context.beginPDFPage(nil)
            let text = CTLineCreateWithAttributedString(NSAttributedString(
                string: page,
                attributes: [kCTFontAttributeName as NSAttributedString.Key: font]
            ))
            context.textPosition = CGPoint(x: 48, y: 650)
            CTLineDraw(text, context)
            context.endPDFPage()
        }
        context.closePDF()
    }

    func testAcceptedOfferImportReviewChecklistExportAndReopen() async throws {
        let dir = try root()
        defer { try? FileManager.default.removeItem(at: dir) }
        let first = dir.appendingPathComponent("fictional-offer.pdf")
        let second = dir.appendingPathComponent("fictional-addendum.pdf")
        let third = dir.appendingPathComponent("fictional-unresolved.pdf")
        try makePDF(first, pages: [
            "Acceptance Date: 2026-11-20",
            "Purchase Price: $650,000.00"
        ])
        try makePDF(second, pages: [
            "Closing Date: 2026-12-21",
            "Purchase Price: $675,000.00"
        ])
        try makePDF(third, pages: ["Closing Date: TBD"])
        let originals = [first, second, third]
        let address = "123 Example Lane"

        let documents = try DocumentWorkspace(
            databaseURL: dir.appendingPathComponent("documents.sqlite"),
            documentsRoot: dir.appendingPathComponent("originals")
        )
        let service = try SorrelgateService(store: SQLiteTransactionStore(
            fileURL: dir.appendingPathComponent("transactions.sqlite")
        ))
        let coordinator = TransactionInitializationCoordinator(
            service: service, workspace: documents
        )

        let created = try await coordinator.create(
            propertyAddress: address, workflow: .acceptedOffer, officeID: nil
        )
        XCTAssertTrue(created.checklistReady)
        XCTAssertNil(created.warning)
        let transactionID = created.record.id
        XCTAssertEqual(created.record.propertyAddress, address)
        let tasks = try await documents.checklist(for: transactionID)
        XCTAssertEqual(tasks.count, 12)

        var imported: [ImportedDocument] = []
        for pdf in originals {
            guard case .imported(let original) = try await documents.importPDF(
                pdf, into: transactionID
            ) else { return XCTFail("Expected a new fictional PDF") }
            imported.append(original)
        }
        XCTAssertEqual(try await documents.documents(for: transactionID).count, 3)
        // Import does not autonomously create or confirm consequential facts.
        let beforeReview = try await documents.fieldProposals(for: transactionID)
        XCTAssertTrue(beforeReview.isEmpty)

        let found = try await documents.proposeKeyFacts(in: transactionID)
        XCTAssertEqual(found.count, 4)
        XCTAssertEqual(found.filter { $0.kind == .purchasePrice }.count, 2)
        let acceptance = try XCTUnwrap(found.first { $0.kind == .acceptanceDate })
        let price = try XCTUnwrap(found.first {
            $0.kind == .purchasePrice && $0.value == "$650,000.00"
        })
        let competingPrice = try XCTUnwrap(found.first {
            $0.kind == .purchasePrice && $0.value == "$675,000.00"
        })
        let closing = try XCTUnwrap(found.first { $0.kind == .closingDate })
        let source = try await documents.sourcePDFURL(
            for: acceptance.id, in: transactionID
        )
        XCTAssertEqual(try Data(contentsOf: source), try Data(contentsOf: first))
        let acceptedPage = try XCTUnwrap(PDFDocument(url: source)?
            .page(at: acceptance.pageIndex)?.string)
        XCTAssertTrue(acceptedPage.contains(acceptance.evidence))

        try await documents.reviewFieldProposal(
            acceptance.id, in: transactionID, as: .confirmed
        )
        try await documents.reviewFieldProposal(
            price.id, in: transactionID, as: .confirmed
        )
        do {
            try await documents.reviewFieldProposal(
                competingPrice.id, in: transactionID, as: .confirmed
            )
            XCTFail("Cannot confirm contradictory purchase prices")
        } catch DocumentProcessingError.conflictingConfirmedField {}
        try await documents.reviewFieldProposal(
            competingPrice.id, in: transactionID, as: .rejected
        )
        try await documents.reviewFieldProposal(
            closing.id, in: transactionID, as: .unknown
        )

        let firstTask = try XCTUnwrap(tasks.first)
        try await documents.linkDocument(
            imported[0].id, to: firstTask.id, in: transactionID
        )
        try await documents.updateTask(firstTask.id, in: transactionID, completed: true)
        let folder = dir.appendingPathComponent("outgoing")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let export = try await documents.export(
            transactionID: transactionID, propertyAddress: address, to: folder
        )
        let manifestURL = export.appendingPathComponent("Manifest.json")
        let manifest = try XCTUnwrap(JSONSerialization.jsonObject(
            with: Data(contentsOf: manifestURL)
        ) as? [String: Any])
        let exportedDocs = try XCTUnwrap(manifest["documents"] as? [[String: String]])
        XCTAssertEqual(exportedDocs.count, 3)
        XCTAssertEqual(manifest["propertyAddress"] as? String, address)
        for record in exportedDocs {
            let name = try XCTUnwrap(record["exportName"])
            let digest = try XCTUnwrap(record["sha256"])
            let original = try XCTUnwrap(imported.first { $0.sha256 == digest })
            let originalURL = try await documents.sourcePDFURL(
                documentID: original.id, in: transactionID
            )
            XCTAssertEqual(
                try Data(contentsOf: export.appendingPathComponent(name)),
                try Data(contentsOf: originalURL)
            )
        }
        let checklistText = try String(
            contentsOf: export.appendingPathComponent("Checklist.txt"),
            encoding: .utf8
        )
        XCTAssertTrue(checklistText.contains("[x] " + firstTask.title))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(
            atPath: export.path
        ).filter { $0.hasSuffix(".pdf") }.count, 3)

        // Relaunch-equivalent: close services and open fresh connections.
        let reopened = try DocumentWorkspace(
            databaseURL: dir.appendingPathComponent("documents.sqlite"),
            documentsRoot: dir.appendingPathComponent("originals")
        )
        let reopenedStore = try SQLiteTransactionStore(
            fileURL: dir.appendingPathComponent("transactions.sqlite")
        )
        let reopenedService = SorrelgateService(store: reopenedStore)
        guard case .transactions(let rows) = try reopenedService.execute(.listTransactions)
        else { return XCTFail("Could not read reopened transactions") }
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.id, transactionID)
        let reviewed = try await reopened.fieldProposals(for: transactionID)
        XCTAssertEqual(reviewed.count, 4)
        XCTAssertEqual(reviewed.first { $0.id == acceptance.id }?.status, .confirmed)
        XCTAssertEqual(reviewed.first { $0.id == price.id }?.status, .confirmed)
        XCTAssertEqual(reviewed.first { $0.id == competingPrice.id }?.status, .rejected)
        XCTAssertEqual(reviewed.first { $0.id == closing.id }?.status, .unknown)
        let reopenedTasks = try await reopened.checklist(for: transactionID)
        XCTAssertEqual(reopenedTasks.count, 12)
        XCTAssertTrue(reopenedTasks.first { $0.id == firstTask.id }?.isCompleted == true)
        XCTAssertEqual(
            reopenedTasks.first { $0.id == firstTask.id }?.linkedDocumentID,
            imported[0].id
        )
        let rediscovered = try await reopened.proposeKeyFacts(in: transactionID)
        XCTAssertEqual(rediscovered.count, 4)
        XCTAssertEqual(rediscovered.first { $0.id == price.id }?.status, .confirmed)
    }
}
