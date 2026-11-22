import AppKit
import CoreGraphics
import CoreText
import CryptoKit
import Foundation
import PDFKit
import XCTest
@testable import SorrelgateCore

@MainActor
final class DocumentWorkspaceTests: XCTestCase {
    private func makeTemporaryFolder() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SorrelgateDocumentTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeWorkspace(root: URL) throws -> DocumentWorkspace {
        try DocumentWorkspace(
            databaseURL: root.appendingPathComponent("Documents.sqlite"),
            documentsRoot: root.appendingPathComponent("originals")
        )
    }

    /// Draw a real selectable-text PDF in the test, without distributing any
    /// real estate forms, copyrighted templates or real customer information.
    private func createPDF(at url: URL, text: String) throws {
        guard let consumer = CGDataConsumer(url: url as CFURL) else {
            throw NSError(domain: "Fixtures", code: 1)
        }
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let context = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            throw NSError(domain: "Fixtures", code: 2)
        }
        context.beginPDFPage(nil)
        let font = CTFontCreateWithName("Helvetica" as CFString, 22, nil)
        let line = CTLineCreateWithAttributedString(
            NSAttributedString(
                string: text,
                attributes: [kCTFontAttributeName as NSAttributedString.Key: font]
            )
        )
        context.textPosition = CGPoint(x: 54, y: 650)
        CTLineDraw(line, context)
        context.endPDFPage()
        context.closePDF()
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testPDFImportPreservesBytesExtractsTextAndDetectsDuplicate() async throws {
        let root = try makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("Synthetic_Offer.pdf")
        try createPDF(at: source, text: "This is a synthetic acceptance agreement")
        let input = try Data(contentsOf: source)
        let expected = SHA256.hash(data: input).map {
            String(format: "%02x", $0)
        }.joined()
        let workspace = try makeWorkspace(root: root)
        let transaction = UUID()

        guard case .imported(let document) = try await workspace.importPDF(
            source, into: transaction
        ) else { return XCTFail("Expected an imported document") }
        XCTAssertEqual(document.sha256, expected)
        XCTAssertEqual(document.pageCount, 1)
        let storedURL = await workspace.storedPDFURL(for: document)
        XCTAssertEqual(try Data(contentsOf: storedURL), input)
        let extracted = try await workspace.pageText(documentID: document.id, in: transaction)
        XCTAssertEqual(extracted.count, 1)
        XCTAssertTrue(extracted[0].text.contains("synthetic acceptance"))

        guard case .duplicate(let same) = try await workspace.importPDF(
            source, into: transaction
        ) else { return XCTFail("Expected duplicate detection") }
        XCTAssertEqual(same.id, document.id)
        let documents = try await workspace.documents(for: transaction)
        XCTAssertEqual(documents.count, 1)

        // Copying the source to internal storage must never change its bytes.
        XCTAssertEqual(try Data(contentsOf: source), input)
    }

    func testInvalidPDFRejectedWithoutDatabaseRecords() async throws {
        let root = try makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("invalid.pdf")
        try Data("not a PDF".utf8).write(to: source)
        let transaction = UUID()
        let workspace = try makeWorkspace(root: root)
        do {
            _ = try await workspace.importPDF(source, into: transaction)
            XCTFail("Expected invalid PDF rejection")
        } catch {
            XCTAssertTrue(error is DocumentProcessingError)
        }
        let docs = try await workspace.documents(for: transaction)
        XCTAssertTrue(docs.isEmpty)
    }

    func testChecklistLinksScopedToTransactionAndSurvivesReopen() async throws {
        let root = try makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let pdf = root.appendingPathComponent("notice.pdf")
        try createPDF(at: pdf, text: "Synthetic listing disclosure packet")
        let a = UUID(), b = UUID()
        let taskID: UUID, documentID: UUID

        do {
            let workspace = try makeWorkspace(root: root)
            guard case .imported(let doc) = try await workspace.importPDF(pdf, into: a)
            else { return XCTFail("Expected import") }
            documentID = doc.id
            let task = try await workspace.addTask("Verify seller disclosure", for: a)
            taskID = task.id
            try await workspace.linkDocument(doc.id, to: task.id, in: a)
            try await workspace.updateTask(task.id, in: a, completed: true)
            let foreign = try await workspace.addTask("Other transaction", for: b)
            do {
                try await workspace.linkDocument(doc.id, to: foreign.id, in: b)
                XCTFail("Cross-transaction link should be denied")
            } catch {
                XCTAssertTrue(error is DocumentProcessingError)
            }
        }

        let reopened = try makeWorkspace(root: root)
        let tasks = try await reopened.checklist(for: a)
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.id, taskID)
        XCTAssertEqual(tasks.first?.linkedDocumentID, documentID)
        XCTAssertTrue(tasks.first?.isCompleted == true)
        let reopenedDocuments = try await reopened.documents(for: a)
        XCTAssertEqual(reopenedDocuments.first?.id, documentID)
    }

    func testExportCopiesVerifiedOriginalAndCreatesManifest() async throws {
        let root = try makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let pdf = root.appendingPathComponent("Simple Form.pdf")
        try createPDF(at: pdf, text: "Testing harmless export of copies")
        let workspace = try makeWorkspace(root: root)
        let transaction = UUID()
        guard case .imported(let imported) = try await workspace.importPDF(
            pdf, into: transaction
        ) else { return XCTFail("Expected import") }
        let task = try await workspace.addTask("Obtain completed forms", for: transaction)
        try await workspace.linkDocument(imported.id, to: task.id, in: transaction)
        let target = root.appendingPathComponent("exports")
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)

        let output = try await workspace.export(
            transactionID: transaction,
            propertyAddress: "12 Harmless Test Street",
            to: target
        )
        let filenames = try FileManager.default.contentsOfDirectory(atPath: output.path)
        XCTAssertTrue(filenames.contains("Manifest.json"))
        XCTAssertTrue(filenames.contains("Checklist.txt"))
        let pdfName = try XCTUnwrap(filenames.first(where: { $0.hasSuffix(".pdf") }))
        XCTAssertEqual(
            try Data(contentsOf: output.appendingPathComponent(pdfName)),
            try Data(contentsOf: pdf)
        )
        let manifest = try Data(contentsOf: output.appendingPathComponent("Manifest.json"))
        let text = try XCTUnwrap(String(data: manifest, encoding: .utf8))
        XCTAssertTrue(text.contains(imported.sha256))
        XCTAssertTrue(text.contains("12 Harmless Test Street"))
    }


    func testStarterChecklistCountsAndIdempotence() async throws {
        let root = try makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let workspace = try makeWorkspace(root: root)
        let listing = UUID(), accepted = UUID(), customID = UUID()
        let a = try await workspace.seedStarterChecklist(
            for: listing, workflow: .listingPreparation
        )
        XCTAssertEqual(a, 9)
        let b = try await workspace.seedStarterChecklist(
            for: accepted, workflow: .acceptedOffer
        )
        XCTAssertEqual(b, 12)
        let repeated = try await workspace.seedStarterChecklist(
            for: listing, workflow: .listingPreparation
        )
        XCTAssertEqual(repeated, 0)
        _ = try await workspace.addTask("Unique office task", for: customID)
        let skipped = try await workspace.seedStarterChecklist(
            for: customID, workflow: .acceptedOffer
        )
        XCTAssertEqual(skipped, 0)
        let existing = try await workspace.checklist(for: customID)
        XCTAssertEqual(existing.map(\.title), ["Unique office task"])
        let listingItems = try await workspace.checklist(for: listing)
        XCTAssertEqual(listingItems.first?.title, "Receive signed listing agreement")
    }

    func testStarterAndTaskEditsPersistAcrossReopen() async throws {
        let root = try makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let transaction = UUID(), other = UUID()
        let firstID: UUID
        do {
            let workspace = try makeWorkspace(root: root)
            let count = try await workspace.seedStarterChecklist(
                for: transaction, workflow: .acceptedOffer
            )
            XCTAssertEqual(count, 12)
            let tasks = try await workspace.checklist(for: transaction)
            firstID = try XCTUnwrap(tasks.first?.id)
            do {
                try await workspace.renameTask(firstID, in: other, to: "Unauthorized")
                XCTFail("Cross-transaction rename must fail")
            } catch {
                XCTAssertTrue(error is DocumentProcessingError)
            }
            try await workspace.renameTask(firstID, in: transaction, to: "Office paperwork")
        }
        let reopened = try makeWorkspace(root: root)
        let tasks = try await reopened.checklist(for: transaction)
        XCTAssertEqual(tasks.count, 12)
        XCTAssertEqual(tasks.first?.title, "Office paperwork")
        do {
            try await reopened.removeTask(firstID, in: other)
            XCTFail("Cross-transaction deletion must fail")
        } catch {
            XCTAssertTrue(error is DocumentProcessingError)
        }
        try await reopened.removeTask(firstID, in: transaction)
        let after = try await reopened.checklist(for: transaction)
        XCTAssertEqual(after.count, 11)
    }

    func testImportManyIndependentSyntheticPDFs() async throws {
        let root = try makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let workspace = try makeWorkspace(root: root)
        let transaction = UUID()
        for index in 1...10 {
            let pdf = root.appendingPathComponent("synthetic-\(index).pdf")
            try createPDF(at: pdf, text: "Synthetic PDF number \(index) distinct pages")
            guard case .imported = try await workspace.importPDF(pdf, into: transaction)
            else { return XCTFail("Expected distinct file") }
        }
        let batch = try await workspace.documents(for: transaction)
        XCTAssertEqual(batch.count, 10)
    }

    /// A known document UUID alone must not disclose another transaction's
    /// original or cached OCR text. Tampered originals must also block reads.
    func testScopedDocumentReadsRejectForeignIDsAndCorruptedOriginals() async throws {
        let root = try makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let aURL = root.appendingPathComponent("transaction-a.pdf")
        let bURL = root.appendingPathComponent("transaction-b.pdf")
        try createPDF(at: aURL, text: "Synthetic private terms transaction Alpha")
        try createPDF(at: bURL, text: "Synthetic private terms transaction Beta")
        let workspace = try makeWorkspace(root: root)
        let a = UUID(), b = UUID()
        guard case .imported(let docA) = try await workspace.importPDF(aURL, into: a),
              case .imported(let docB) = try await workspace.importPDF(bURL, into: b)
        else { return XCTFail("Expected two imported fictional originals") }

        let permitted = try await workspace.sourcePDFURL(documentID: docA.id, in: a)
        XCTAssertEqual(try Data(contentsOf: permitted), try Data(contentsOf: aURL))
        let pageA = try await workspace.pageText(documentID: docA.id, in: a)
        XCTAssertTrue(pageA[0].text.contains("Alpha"))

        for (documentID, owner) in [(docA.id, b), (docB.id, a), (UUID(), a)] {
            do {
                _ = try await workspace.sourcePDFURL(documentID: documentID, in: owner)
                XCTFail("Foreign or unknown document ID must not return a source path")
            } catch DocumentProcessingError.missingDocument {}
            do {
                _ = try await workspace.pageText(documentID: documentID, in: owner)
                XCTFail("Foreign or unknown document ID must not disclose page text")
            } catch DocumentProcessingError.missingDocument {}
        }
        // Corrupting an archived original must not leak its previously cached
        // extracted text under a valid transaction ID.
        let storedB = await workspace.storedPDFURL(for: docB)
        try Data("tampered".utf8).write(to: storedB)
        do {
            _ = try await workspace.sourcePDFURL(documentID: docB.id, in: b)
            XCTFail("Stored PDF integrity must be checked before preview")
        } catch DocumentProcessingError.corruptedOriginal {}
        do {
            _ = try await workspace.pageText(documentID: docB.id, in: b)
            XCTFail("Cached OCR/text must not bypass corrupted-source checks")
        } catch DocumentProcessingError.corruptedOriginal {}
        let reopened = try makeWorkspace(root: root)
        let stillA = try await reopened.pageText(documentID: docA.id, in: a)
        XCTAssertEqual(stillA, pageA)
    }
}
