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
        let extracted = try await workspace.pageText(documentID: document.id)
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
}
