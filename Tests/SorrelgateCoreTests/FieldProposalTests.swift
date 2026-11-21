import AppKit
import CoreGraphics
import CoreText
import CryptoKit
import Foundation
import PDFKit
import XCTest
@testable import SorrelgateCore

/// First G1 acceptance tests use real PDFKit text and SQLite persistence.
/// No model, mocked OCR, licensed office form or customer data is involved.
@MainActor
final class FieldProposalTests: XCTestCase {
    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SorrelgateFieldReview-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeWorkspace(_ root: URL) throws -> DocumentWorkspace {
        try DocumentWorkspace(
            databaseURL: root.appendingPathComponent("documents.sqlite"),
            documentsRoot: root.appendingPathComponent("originals")
        )
    }

    private func makePDF(_ url: URL, lines: [String]) throws {
        guard let consumer = CGDataConsumer(url: url as CFURL) else {
            throw NSError(domain: "FieldFixture", code: 1)
        }
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let context = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            throw NSError(domain: "FieldFixture", code: 2)
        }
        let font = CTFontCreateWithName("Helvetica" as CFString, 22, nil)
        for line in lines {
            context.beginPDFPage(nil)
            let text = CTLineCreateWithAttributedString(NSAttributedString(
                string: line,
                attributes: [kCTFontAttributeName as NSAttributedString.Key: font]
            ))
            context.textPosition = CGPoint(x: 48, y: 650)
            CTLineDraw(text, context)
            context.endPDFPage()
        }
        context.closePDF()
    }

    private func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    func testSourceLinkedReviewPersistsAndNeverCrossesTransactions() async throws {
        let root = try directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("synthetic-accepted-offer.pdf")
        try makePDF(source, lines: [
            "Synthetic transaction cover",
            "Acceptance Date: 2026-11-20",
            "No further acceptance date on this page"
        ])
        let original = try Data(contentsOf: source)
        let workspace = try makeWorkspace(root)
        let transactionA = UUID(), transactionB = UUID()
        guard case .imported(let documentA) = try await workspace.importPDF(
            source, into: transactionA
        ) else { return XCTFail("Transaction A import failed") }
        guard case .imported(let documentB) = try await workspace.importPDF(
            source, into: transactionB
        ) else { return XCTFail("Transaction B import failed") }

        // Import alone does not infer or confirm a consequential date.
        let noneBeforeDiscovery = try await workspace.fieldProposals(for: transactionA)
        XCTAssertTrue(noneBeforeDiscovery.isEmpty)

        let proposalsA = try await workspace.proposeAcceptanceDates(
            from: documentA.id, in: transactionA
        )
        XCTAssertEqual(proposalsA.count, 1)
        let proposal = try XCTUnwrap(proposalsA.first)
        XCTAssertEqual(proposal.transactionID, transactionA)
        XCTAssertEqual(proposal.documentID, documentA.id)
        XCTAssertEqual(proposal.sourceSHA256, hash(original))
        XCTAssertEqual(proposal.pageIndex, 1)
        XCTAssertEqual(proposal.kind, .acceptanceDate)
        XCTAssertEqual(proposal.value, "2026-11-20")
        XCTAssertEqual(proposal.evidence, "Acceptance Date: 2026-11-20")
        XCTAssertEqual(proposal.status, .proposed)

        let sourceURL = try await workspace.sourcePDFURL(
            for: proposal.id, in: transactionA
        )
        XCTAssertEqual(try Data(contentsOf: sourceURL), original)
        let pdf = try XCTUnwrap(PDFDocument(url: sourceURL))
        XCTAssertEqual(pdf.pageCount, 3)
        XCTAssertTrue(try XCTUnwrap(pdf.page(at: proposal.pageIndex)?.string)
            .contains(proposal.evidence))

        do {
            _ = try await workspace.proposeAcceptanceDates(
                from: documentA.id, in: transactionB
            )
            XCTFail("A different transaction must not read this document's evidence")
        } catch DocumentProcessingError.missingDocument {
            // No cross-transaction proposals or document text access.
        }
        do {
            _ = try await workspace.sourcePDFURL(for: proposal.id, in: transactionB)
            XCTFail("Cross-transaction evidence access must fail")
        } catch DocumentProcessingError.missingFieldProposal {}

        do {
            try await workspace.reviewFieldProposal(
                proposal.id, in: transactionB, as: .confirmed
            )
            XCTFail("Cross-transaction confirmation must fail")
        } catch DocumentProcessingError.missingFieldProposal {}

        try await workspace.reviewFieldProposal(
            proposal.id, in: transactionA, as: .confirmed
        )
        let rediscovered = try await workspace.proposeAcceptanceDates(
            from: documentA.id, in: transactionA
        )
        XCTAssertEqual(rediscovered.count, 1)
        XCTAssertEqual(rediscovered[0].id, proposal.id)
        XCTAssertEqual(rediscovered[0].status, .confirmed)

        // Same source bytes but separate transaction means separate proposal.
        let proposalsB = try await workspace.proposeAcceptanceDates(
            from: documentB.id, in: transactionB
        )
        XCTAssertEqual(proposalsB.count, 1)
        XCTAssertNotEqual(proposalsB[0].id, proposal.id)
        XCTAssertEqual(proposalsB[0].status, .proposed)

        let reopened = try makeWorkspace(root)
        let storedA = try await reopened.fieldProposals(for: transactionA)
        let storedB = try await reopened.fieldProposals(for: transactionB)
        XCTAssertEqual(storedA.count, 1)
        XCTAssertEqual(storedB.count, 1)
        XCTAssertEqual(storedA[0].status, .confirmed)
        XCTAssertEqual(storedB[0].status, .proposed)
        XCTAssertEqual(storedA[0].sourceSHA256, hash(original))
        XCTAssertEqual(try Data(contentsOf: source), original)

        try await reopened.reviewFieldProposal(
            proposal.id, in: transactionA, as: .unknown
        )
        let nowUnknown = try await reopened.fieldProposals(for: transactionA)
        XCTAssertEqual(nowUnknown[0].status, .unknown)
        try await reopened.reviewFieldProposal(
            proposal.id, in: transactionA, as: .rejected
        )
        let nowRejected = try await reopened.fieldProposals(for: transactionA)
        XCTAssertEqual(nowRejected[0].status, .rejected)
        let stillUnverifiedB = try await reopened.fieldProposals(for: transactionB)
        XCTAssertEqual(stillUnverifiedB[0].status, .proposed)

        do {
            try await reopened.reviewFieldProposal(
                proposal.id, in: transactionA, as: .proposed
            )
            XCTFail("This slice must not silently revert human decision")
        } catch DocumentProcessingError.invalidFieldReviewStatus {}
    }

    func testUnknownAndImpossibleDateNeverBecomeProposals() async throws {
        let root = try directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("unknown.pdf")
        try makePDF(source, lines: [
            "Offer accepted on November 21, 2026",
            "Acceptance Date: TBD",
            "Acceptance Date: 2026-02-30",
            "The close date is unverified"
        ])
        let workspace = try makeWorkspace(root)
        let transaction = UUID()
        guard case .imported(let document) = try await workspace.importPDF(
            source, into: transaction
        ) else { return XCTFail("Expected import") }
        let candidates = try await workspace.proposeAcceptanceDates(
            from: document.id, in: transaction
        )
        XCTAssertTrue(candidates.isEmpty, "No guessing, invalid calendar, or fallback dates")
        let persisted = try await workspace.fieldProposals(for: transaction)
        XCTAssertTrue(persisted.isEmpty)
        let reopened = try makeWorkspace(root)
        let reopenedProposals = try await reopened.fieldProposals(for: transaction)
        XCTAssertTrue(reopenedProposals.isEmpty)
    }

    func testCorruptedOriginalBlocksReviewAndSourcePreviewWithoutChangingDecisions() async throws {
        let root = try directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("accepted.pdf")
        try makePDF(source, lines: ["Acceptance Date: 2026-11-20"])
        let original = try Data(contentsOf: source)
        let workspace = try makeWorkspace(root)
        let transaction = UUID()
        guard case .imported(let document) = try await workspace.importPDF(
            source, into: transaction
        ) else { return XCTFail("Expected import") }
        let candidates = try await workspace.proposeAcceptanceDates(
            from: document.id, in: transaction
        )
        let candidate = try XCTUnwrap(candidates.first)
        let storedURL = await workspace.storedPDFURL(for: document)
        try Data("deliberate archive corruption".utf8).write(to: storedURL)

        do {
            _ = try await workspace.sourcePDFURL(for: candidate.id, in: transaction)
            XCTFail("Source preview must never open wrong bytes")
        } catch DocumentProcessingError.corruptedOriginal {}
        do {
            try await workspace.reviewFieldProposal(
                candidate.id, in: transaction, as: .confirmed
            )
            XCTFail("Do not confirm against corrupted provenance")
        } catch DocumentProcessingError.corruptedOriginal {}
        do {
            _ = try await workspace.proposeAcceptanceDates(
                from: document.id, in: transaction
            )
            XCTFail("Discovery must reject corrupted originals")
        } catch DocumentProcessingError.corruptedOriginal {}
        let after = try await workspace.fieldProposals(for: transaction)
        XCTAssertEqual(after.count, 1)
        XCTAssertEqual(after[0].status, .proposed)

        try original.write(to: storedURL)
        try await workspace.reviewFieldProposal(
            candidate.id, in: transaction, as: .confirmed
        )
        let confirmed = try await workspace.fieldProposals(for: transaction)
        XCTAssertEqual(confirmed[0].status, .confirmed)
        XCTAssertEqual(try Data(contentsOf: source), original)
    }
}
