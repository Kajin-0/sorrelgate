import AppKit
import CoreGraphics
import CoreText
import CryptoKit
import Foundation
import PDFKit
import SQLite3
import XCTest
@testable import SorrelgateCore

/// All fixtures are generated in CI. No licensed forms or customer data.
@MainActor
final class PDFReliabilityTests: XCTestCase {
    private func fixtureRoot() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Sorrelgate-M1-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func workspace(_ root: URL) throws -> DocumentWorkspace {
        try DocumentWorkspace(
            databaseURL: root.appendingPathComponent("documents.sqlite"),
            documentsRoot: root.appendingPathComponent("originals")
        )
    }

    private func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func createDigitalPDF(at url: URL, identifier: Int) throws {
        guard let consumer = CGDataConsumer(url: url as CFURL) else {
            throw NSError(domain: "M1Fixtures", code: 1)
        }
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let pdf = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw NSError(domain: "M1Fixtures", code: 2)
        }
        pdf.beginPDFPage(nil)
        let font = CTFontCreateWithName("Helvetica" as CFString, 22, nil)
        let line = CTLineCreateWithAttributedString(NSAttributedString(
            string: "Synthetic seller-side record number \(identifier) ready for review",
            attributes: [kCTFontAttributeName as NSAttributedString.Key: font]
        ))
        pdf.textPosition = CGPoint(x: 48, y: 650)
        CTLineDraw(line, pdf)
        pdf.endPDFPage()
        pdf.closePDF()
    }

    /// Renders letter-sized raster pixels first, then embeds the bitmap in PDF.
    /// No embedded PDF text layer exists: any recognized words must come from
    /// PDFKit rasterization followed by the real Apple Vision OCR path.
    private func createRasterPDF(at url: URL, identifier: Int) throws {
        guard let bitmap = CGContext(
            data: nil, width: 1600, height: 2000,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw NSError(domain: "M1Fixtures", code: 3) }
        bitmap.setFillColor(CGColor(gray: 1, alpha: 1))
        bitmap.fill(CGRect(x: 0, y: 0, width: 1600, height: 2000))
        bitmap.setFillColor(CGColor(gray: 0, alpha: 1))
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 68, nil)
        let lines = [
            "SORRELGATE SYNTHETIC RECEIPT",
            "SELLER DOCUMENT REVIEW ALPHA",
            "REFERENCE NUMBER \(identifier)"
        ]
        for (index, text) in lines.enumerated() {
            let line = CTLineCreateWithAttributedString(NSAttributedString(
                string: text,
                attributes: [kCTFontAttributeName as NSAttributedString.Key: font]
            ))
            bitmap.textPosition = CGPoint(x: 100, y: CGFloat(1600 - index * 165))
            CTLineDraw(line, bitmap)
        }
        guard let image = bitmap.makeImage(),
              let consumer = CGDataConsumer(url: url as CFURL) else {
            throw NSError(domain: "M1Fixtures", code: 4)
        }
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let pdf = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            throw NSError(domain: "M1Fixtures", code: 5)
        }
        pdf.beginPDFPage(nil)
        pdf.draw(image, in: box)
        pdf.endPDFPage()
        pdf.closePDF()
    }

    private func words(_ text: String) -> Set<String> {
        Set(text.uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty })
    }

    private func tokenRecall(_ text: String) -> Double {
        let expected: Set<String> = [
            "SORRELGATE", "SYNTHETIC", "RECEIPT", "SELLER",
            "DOCUMENT", "REVIEW", "ALPHA"
        ]
        return Double(words(text).intersection(expected).count) /
            Double(expected.count)
    }

    private func checkNoStagingFiles(root: URL, transactionID: UUID) throws {
        let directory = root.appendingPathComponent("originals")
            .appendingPathComponent(transactionID.uuidString)
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        let filenames = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertFalse(
            filenames.contains(where: { $0.hasPrefix(".incoming-") }),
            "Temporary imports must be deleted after cancellation or failure."
        )
    }

    func testRealVisionOnRasterOnlyPDFAndIntegrity() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("raster-receipt.pdf")
        try createRasterPDF(at: source, identifier: 8123)
        let original = try Data(contentsOf: source)
        let pdf = try XCTUnwrap(PDFDocument(url: source))
        XCTAssertEqual(pdf.pageCount, 1)
        let page = try XCTUnwrap(pdf.page(at: 0))
        XCTAssertTrue((page.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        let store = try workspace(root)
        let transaction = UUID()
        guard case .imported(let doc) = try await store.importPDF(source, into: transaction)
        else { return XCTFail("Expected a real raster OCR import") }
        let extracted = try await store.pageText(documentID: doc.id)
        XCTAssertEqual(extracted.count, 1)
        XCTAssertEqual(extracted[0].method, .vision)
        let recall = tokenRecall(extracted[0].text)
        print(String(format: "M1_OCR_CI token_recall=%.3f expected_terms=7 method=Vision", recall))
        XCTAssertGreaterThanOrEqual(recall, 0.85)
        XCTAssertTrue(extracted[0].text.contains("8123") || words(extracted[0].text).contains("8123"))
        XCTAssertEqual(doc.sha256, digest(original))
        let saved = await store.storedPDFURL(for: doc)
        XCTAssertEqual(try Data(contentsOf: saved), original)
        XCTAssertEqual(try Data(contentsOf: source), original)
    }

    func testPreCancelledImportLeavesNoRecordsAndRetrySucceeds() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("cancel.pdf")
        try createDigitalPDF(at: source, identifier: 10)
        let bytes = try Data(contentsOf: source)
        let store = try workspace(root)
        let transaction = UUID()
        let attempt = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await store.importPDF(source, into: transaction)
        }
        do {
            _ = try await attempt.value
            XCTFail("Cancelled import unexpectedly committed")
        } catch is CancellationError {
            // Expected before source copy, or during its cancellable task.
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
        let none = try await store.documents(for: transaction)
        XCTAssertTrue(none.isEmpty)
        try checkNoStagingFiles(root: root, transactionID: transaction)
        XCTAssertEqual(try Data(contentsOf: source), bytes)
        guard case .imported = try await store.importPDF(source, into: transaction)
        else { return XCTFail("Retry must import cleanly") }
        let resumeCount = try await awaitDocumentCount(store, transaction)
        XCTAssertEqual(resumeCount, 1)
    }

    func testCancelledMultiFileBatchPreservesCompletedAndAllowsResume() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try workspace(root)
        let transaction = UUID()
        var sources: [URL] = []
        for index in 1...8 {
            let source = root.appendingPathComponent("batch-\(index).pdf")
            try createDigitalPDF(at: source, identifier: index)
            sources.append(source)
        }
        let batch = Task {
            var completed = 0
            for source in sources {
                try Task<Never, Never>.checkCancellation()
                _ = try await store.importPDF(source, into: transaction)
                completed += 1
                if completed == 3 {
                    withUnsafeCurrentTask { $0?.cancel() }
                    break
                }
            }
            return completed
        }
        let completed = try await batch.value
        XCTAssertEqual(completed, 3)
        let before = try await store.documents(for: transaction)
        XCTAssertEqual(before.count, 3)
        for source in sources.dropFirst(3) {
            guard case .imported = try await store.importPDF(source, into: transaction)
            else { return XCTFail("Remaining files must be importable after cancellation") }
        }
        let after = try await store.documents(for: transaction)
        XCTAssertEqual(after.count, 8)
        XCTAssertTrue(Set(before.map(\.id)).isSubset(of: Set(after.map(\.id))))
        try checkNoStagingFiles(root: root, transactionID: transaction)
    }

    func testFilesystemObstructionDoesNotModifySourceOrCreateRecords() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("blocked.pdf")
        try createDigitalPDF(at: source, identifier: 99)
        let original = try Data(contentsOf: source)
        let store = try workspace(root)
        let transaction = UUID()
        let blocker = root.appendingPathComponent("originals")
            .appendingPathComponent(transaction.uuidString)
        try Data("not a directory".utf8).write(to: blocker)
        do {
            _ = try await store.importPDF(source, into: transaction)
            XCTFail("A regular file obstructing the destination directory must fail")
        } catch {
            // The OS rejects creating a directory over a file.
        }
        XCTAssertEqual(try Data(contentsOf: blocker), Data("not a directory".utf8))
        XCTAssertEqual(try Data(contentsOf: source), original)
        let none = try await store.documents(for: transaction)
        XCTAssertTrue(none.isEmpty)
        try FileManager.default.removeItem(at: blocker)
        guard case .imported = try await store.importPDF(source, into: transaction)
        else { return XCTFail("Import should resume after storage is available") }
        let databaseRetryCount = try await awaitDocumentCount(store, transaction)
        XCTAssertEqual(databaseRetryCount, 1)
    }

    func testFailedSQLiteCommitRemovesNewOriginalThenRetryWorks() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("db-fault.pdf")
        try createDigitalPDF(at: source, identifier: 202)
        let original = try Data(contentsOf: source)
        let store = try workspace(root)
        let transaction = UUID()
        var db: OpaquePointer?
        XCTAssertEqual(sqlite3_open(root.appendingPathComponent("documents.sqlite").path, &db), SQLITE_OK)
        defer { if let db { sqlite3_close(db) } }
        let failureTrigger = """
            CREATE TRIGGER M1_force_failure BEFORE INSERT ON documents
            BEGIN SELECT RAISE(ABORT, 'simulated SQLite write fault'); END;
            """
        XCTAssertEqual(sqlite3_exec(db, failureTrigger, nil, nil, nil), SQLITE_OK)
        do {
            _ = try await store.importPDF(source, into: transaction)
            XCTFail("Synthetic DB failure must abort the document commit")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("simulated SQLite write fault"))
        }
        let afterFaultCount = try await awaitDocumentCount(store, transaction)
        XCTAssertEqual(afterFaultCount, 0)
        let dest = root.appendingPathComponent("originals")
            .appendingPathComponent(transaction.uuidString)
            .appendingPathComponent(digest(original) + ".pdf")
        XCTAssertFalse(FileManager.default.fileExists(atPath: dest.path))
        try checkNoStagingFiles(root: root, transactionID: transaction)
        XCTAssertEqual(try Data(contentsOf: source), original)
        XCTAssertEqual(sqlite3_exec(db, "DROP TRIGGER M1_force_failure;", nil, nil, nil), SQLITE_OK)
        guard case .imported(let created) = try await store.importPDF(source, into: transaction)
        else { return XCTFail("Retry after DB rollback must work") }
        XCTAssertEqual(created.sha256, digest(original))
        let finalRetryCount = try await awaitDocumentCount(store, transaction)
        XCTAssertEqual(finalRetryCount, 1)
    }

    func testCorruptedExistingDestinationIsNeverOverwritten() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("original.pdf")
        try createDigitalPDF(at: source, identifier: 303)
        let original = try Data(contentsOf: source)
        let store = try workspace(root)
        let transaction = UUID()
        let directory = root.appendingPathComponent("originals")
            .appendingPathComponent(transaction.uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let collision = directory.appendingPathComponent(digest(original) + ".pdf")
        let badBytes = Data("PREEXISTING CORRUPTED FILE".utf8)
        try badBytes.write(to: collision)
        do {
            _ = try await store.importPDF(source, into: transaction)
            XCTFail("Mismatched stored hash should be rejected")
        } catch DocumentProcessingError.corruptedOriginal {
            // Expected; neither the source nor destination may be overwritten.
        }
        XCTAssertEqual(try Data(contentsOf: collision), badBytes)
        XCTAssertEqual(try Data(contentsOf: source), original)
        let collisionCount = try await awaitDocumentCount(store, transaction)
        XCTAssertEqual(collisionCount, 0)
        try checkNoStagingFiles(root: root, transactionID: transaction)
    }

    func test50PDFMixedDigitalRasterBenchmarkAndReopen() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try workspace(root)
        let transaction = UUID()
        let rasterIndices: Set<Int> = [9, 19, 29, 39]
        var durations: [Double] = []
        var expectedFiles: [(ImportedDocument, Data, ExtractedTextMethod)] = []
        let start = ProcessInfo.processInfo.systemUptime

        for index in 0..<50 {
            let source = root.appendingPathComponent("synthetic-\(index).pdf")
            let isRaster = rasterIndices.contains(index)
            if isRaster {
                try createRasterPDF(at: source, identifier: 1000 + index)
            } else {
                try createDigitalPDF(at: source, identifier: 1000 + index)
            }
            let original = try Data(contentsOf: source)
            let t0 = ProcessInfo.processInfo.systemUptime
            guard case .imported(let document) = try await store.importPDF(
                source, into: transaction
            ) else { return XCTFail("All 50 distinct documents must import") }
            durations.append(ProcessInfo.processInfo.systemUptime - t0)
            let method: ExtractedTextMethod = isRaster ? .vision : .digital
            expectedFiles.append((document, original, method))
            XCTAssertEqual(document.sha256, digest(original))
            XCTAssertEqual(document.pageCount, 1)
        }
        let elapsed = ProcessInfo.processInfo.systemUptime - start
        let sorted = durations.sorted()
        let p50 = sorted[24]
        let p95 = sorted[47]
        print(String(format:
            "M1_BATCH_CI files=50 digital=46 raster=4 duration_s=%.3f throughput_files_per_s=%.3f p50_import_s=%.3f p95_import_s=%.3f",
            elapsed, 50.0 / max(elapsed, 0.001), p50, p95
        ))
        let all = try await store.documents(for: transaction)
        XCTAssertEqual(all.count, 50)
        XCTAssertEqual(Set(all.map(\.sha256)).count, 50)
        for (document, original, method) in expectedFiles {
            let originalURL = await store.storedPDFURL(for: document)
            XCTAssertEqual(try Data(contentsOf: originalURL), original)
            let pages = try await store.pageText(documentID: document.id)
            XCTAssertEqual(pages.count, 1)
            XCTAssertEqual(pages.first?.method, method)
            if method == .vision {
                let recall = tokenRecall(pages[0].text)
                XCTAssertGreaterThanOrEqual(recall, 0.70)
            }
        }
        try checkNoStagingFiles(root: root, transactionID: transaction)
        let reopened = try workspace(root)
        let again = try await reopened.documents(for: transaction)
        XCTAssertEqual(again.count, 50)
        XCTAssertEqual(Set(again.map(\.id)), Set(all.map(\.id)))
        let reopenedCount = try await awaitDocumentCount(reopened, transaction)
        XCTAssertEqual(reopenedCount, 50)
    }

    private func awaitDocumentCount(
        _ store: DocumentWorkspace, _ transactionID: UUID
    ) async throws -> Int {
        try await store.documents(for: transactionID).count
    }
}
