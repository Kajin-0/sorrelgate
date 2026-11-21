import AppKit
import CoreGraphics
import CoreImage
import CoreText
import CryptoKit
import Darwin
import Foundation
import PDFKit
import XCTest
@testable import SorrelgateCore

/// Synthetic-only quality gates. Image-only samples never include PDF text.
/// The FIFO test cancels while the file-copy read loop is actively waiting.
@MainActor
final class PDFHardeningTests: XCTestCase {
    private func root() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("sorrelgate-hardening-" + UUID().uuidString)
        try FileManager.default.createDirectory(
            at: url, withIntermediateDirectories: true
        )
        return url
    }

    private func workspace(_ root: URL) throws -> DocumentWorkspace {
        try DocumentWorkspace(
            databaseURL: root.appendingPathComponent("documents.sqlite"),
            documentsRoot: root.appendingPathComponent("originals")
        )
    }

    private func sha(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func createDigitalPDF(_ url: URL) throws {
        guard let consumer = CGDataConsumer(url: url as CFURL) else {
            throw NSError(domain: "PDFHardening", code: 1)
        }
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let context = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            throw NSError(domain: "PDFHardening", code: 2)
        }
        context.beginPDFPage(nil)
        let line = CTLineCreateWithAttributedString(NSAttributedString(
            string: "Synthetic office acceptance paperwork reference 8256",
            attributes: [
                kCTFontAttributeName as NSAttributedString.Key:
                    CTFontCreateWithName("Helvetica" as CFString, 22, nil)
            ]
        ))
        context.textPosition = CGPoint(x: 46, y: 650)
        CTLineDraw(line, context)
        context.endPDFPage()
        context.closePDF()
    }

    private struct RasterCase {
        let label: String
        let grayscale: CGFloat
        let tiltDegrees: CGFloat
        let blurRadius: CGFloat
    }

    private let rasterCases: [RasterCase] = [
        .init(label: "ALPHA", grayscale: 0, tiltDegrees: 0, blurRadius: 0),
        .init(label: "BRAVO", grayscale: 0, tiltDegrees: 4, blurRadius: 0),
        .init(label: "CHARLIE", grayscale: 0.48, tiltDegrees: 0, blurRadius: 0),
        .init(label: "DELTA", grayscale: 0, tiltDegrees: 0, blurRadius: 2.2)
    ]

    private func createFivePageRasterPDF(_ url: URL) throws {
        guard let consumer = CGDataConsumer(url: url as CFURL) else {
            throw NSError(domain: "PDFHardening", code: 3)
        }
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let pdf = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            throw NSError(domain: "PDFHardening", code: 4)
        }

        let configurations = rasterCases.map { Optional($0) } + [nil]
        for configuration in configurations {
            guard let bitmap = CGContext(
                data: nil, width: 1400, height: 1800,
                bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { throw NSError(domain: "PDFHardening", code: 5) }
            bitmap.setFillColor(CGColor(gray: 1, alpha: 1))
            bitmap.fill(CGRect(x: 0, y: 0, width: 1400, height: 1800))
            if let configuration {
                bitmap.saveGState()
                bitmap.translateBy(x: 100, y: 1450)
                bitmap.rotate(by: configuration.tiltDegrees * .pi / 180)
                bitmap.setFillColor(CGColor(gray: configuration.grayscale, alpha: 1))
                let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 59, nil)
                let strings = [
                    "SORRELGATE SYNTHETIC PAGE",
                    "SELLER DOCUMENT REVIEW",
                    "SECTION \(configuration.label)"
                ]
                for (index, string) in strings.enumerated() {
                    let line = CTLineCreateWithAttributedString(NSAttributedString(
                        string: string,
                        attributes: [kCTFontAttributeName as NSAttributedString.Key: font]
                    ))
                    bitmap.textPosition = CGPoint(x: 0, y: -CGFloat(index * 144))
                    CTLineDraw(line, bitmap)
                }
                bitmap.restoreGState()
            }
            guard let originalImage = bitmap.makeImage() else {
                throw NSError(domain: "PDFHardening", code: 6)
            }
            let image: CGImage
            if let configuration, configuration.blurRadius > 0 {
                let original = CIImage(cgImage: originalImage)
                let blurred = original.clampedToExtent().applyingFilter(
                    "CIGaussianBlur",
                    parameters: [kCIInputRadiusKey: configuration.blurRadius]
                ).cropped(to: original.extent)
                guard let result = CIContext().createCGImage(
                    blurred, from: original.extent
                ) else { throw NSError(domain: "PDFHardening", code: 7) }
                image = result
            } else {
                image = originalImage
            }
            pdf.beginPDFPage(nil)
            pdf.draw(image, in: box)
            pdf.endPDFPage()
        }
        pdf.closePDF()
    }

    private func expectedRecall(_ text: String, section: String) -> Double {
        let expected: Set<String> = [
            "SORRELGATE", "SYNTHETIC", "SELLER", "DOCUMENT", "REVIEW", "SECTION", section
        ]
        let observed = Set(text.uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty })
        return Double(observed.intersection(expected).count) / Double(expected.count)
    }

    private func emitMetrics(_ text: String) throws {
        print(text)
        if let root = ProcessInfo.processInfo.environment["RUNNER_TEMP"] {
            let file = URL(fileURLWithPath: root, isDirectory: true)
                .appendingPathComponent("sorrelgate-m1-degraded.txt")
            try (text + "\n").write(to: file, atomically: true, encoding: .utf8)
        }
    }

    private func stagingFiles(root: URL, transactionID: UUID) -> [URL] {
        let dir = root.appendingPathComponent("originals")
            .appendingPathComponent(transactionID.uuidString)
        let entries = (try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil
        )) ?? []
        return entries.filter { $0.lastPathComponent.hasPrefix(".incoming-") }
    }

    func testFivePageRasterOCRWithSkewLowContrastBlurAndBlankAbstention() async throws {
        let root = try root()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("raster-multipage.pdf")
        try createFivePageRasterPDF(source)
        let bytes = try Data(contentsOf: source)
        let opened = try XCTUnwrap(PDFDocument(url: source))
        XCTAssertEqual(opened.pageCount, 5)
        for index in 0..<5 {
            let page = try XCTUnwrap(opened.page(at: index))
            XCTAssertTrue(
                (page.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "All \(index) pages must have no embedded text layer."
            )
        }

        let store = try workspace(root)
        let transaction = UUID()
        guard case .imported(let document) = try await store.importPDF(
            source, into: transaction
        ) else { return XCTFail("Expected five-page image-only import") }

        let pages = try await store.pageText(documentID: document.id)
        XCTAssertEqual(document.pageCount, 5)
        XCTAssertEqual(pages.map(\.pageIndex), [0, 1, 2, 3, 4])
        XCTAssertEqual(pages.count, 5)
        var values: [Double] = []
        for (index, fixture) in rasterCases.enumerated() {
            XCTAssertEqual(pages[index].method, .vision, "Image page \(index)")
            let recall = expectedRecall(pages[index].text, section: fixture.label)
            values.append(recall)
            XCTAssertGreaterThanOrEqual(
                recall, 0.70,
                "OCR regression in \(fixture.label) page: \(pages[index].text)"
            )
            XCTAssertTrue(
                pages[index].text.uppercased().contains(fixture.label),
                "Page identity should survive \(fixture.label) degradation."
            )
        }
        XCTAssertEqual(pages[4].method, .unavailable, "Blank page must abstain")
        XCTAssertTrue(pages[4].text.isEmpty)
        try emitMetrics(String(format:
            "M1_MULTIPAGE_OCR_CI pages=5 alpha_recall=%.3f skew4deg_recall=%.3f lowcontrast_recall=%.3f blur2.2px_recall=%.3f blank_abstained=true",
            values[0], values[1], values[2], values[3]
        ))
        XCTAssertEqual(document.sha256, sha(bytes))
        let saved = await store.storedPDFURL(for: document)
        XCTAssertEqual(try Data(contentsOf: saved), bytes)
        XCTAssertEqual(try Data(contentsOf: source), bytes)

        let reopened = try workspace(root)
        let reopenedPages = try await reopened.pageText(documentID: document.id)
        XCTAssertEqual(reopenedPages, pages)
    }

    func testCancelledDuringBlockedFIFOReadLeavesNoOriginalOrDatabaseRow() async throws {
        let root = try root()
        defer { try? FileManager.default.removeItem(at: root) }
        let pipe = root.appendingPathComponent("stream.pdf")
        XCTAssertEqual(Darwin.mkfifo(pipe.path, 0o600), 0)
        let store = try workspace(root)
        let transaction = UUID()
        let closeWriter = DispatchSemaphore(value: 0)

        // Writer supplies one partial chunk and then deliberately holds the FIFO
        // open. The import read loop blocks in its next read until released.
        let writer = Task.detached(priority: .userInitiated) { () -> Int in
            let fd = Darwin.open(pipe.path, O_WRONLY)
            guard fd >= 0 else { return -1 }
            defer { _ = Darwin.close(fd) }
            let payload = Array(repeating: UInt8(0x50), count: 4096)
            let written = payload.withUnsafeBytes { bytes in
                Darwin.write(fd, bytes.baseAddress, bytes.count)
            }
            closeWriter.wait()
            return written
        }
        let importTask = Task.detached(priority: .userInitiated) {
            try await store.importPDF(pipe, into: transaction)
        }
        var sawCopiedBytes = false
        for _ in 0..<500 {
            try await Task.sleep(for: .milliseconds(10))
            if stagingFiles(root: root, transactionID: transaction).contains(where: {
                let size = try? FileManager.default.attributesOfItem(
                    atPath: $0.path
                )[.size] as? NSNumber
                return (size?.intValue ?? 0) > 0
            }) {
                sawCopiedBytes = true
                break
            }
        }
        importTask.cancel()
        closeWriter.signal()
        let written = await writer.value
        XCTAssertEqual(written, 4096, "Test must feed bytes before cancellation.")
        XCTAssertTrue(sawCopiedBytes, "Cancellation must happen after real staged bytes.")
        do {
            _ = try await importTask.value
            XCTFail("Cancelled in-progress copy must not produce a document receipt.")
        } catch is CancellationError {
            // Expected: the next read returns EOF and cancellation is checked.
        } catch {
            XCTFail("Expected a cancellation, received \(error)")
        }
        let documents = try await store.documents(for: transaction)
        XCTAssertTrue(documents.isEmpty)
        XCTAssertTrue(stagingFiles(root: root, transactionID: transaction).isEmpty)
        let directory = root.appendingPathComponent("originals")
            .appendingPathComponent(transaction.uuidString)
        let remaining = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertTrue(remaining.isEmpty, "No final original must remain.")
    }

    func testDuplicateRechecksStoredOriginalIntegrityIncludingMissingFile() async throws {
        let root = try root()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("same.pdf")
        try createDigitalPDF(source)
        let bytes = try Data(contentsOf: source)
        let store = try workspace(root)
        let transaction = UUID()
        guard case .imported(let original) = try await store.importPDF(
            source, into: transaction
        ) else { return XCTFail("Expected import") }
        let stored = await store.storedPDFURL(for: original)

        try Data("Corrupted original, not a PDF".utf8).write(to: stored)
        do {
            _ = try await store.importPDF(source, into: transaction)
            XCTFail("A hash match in SQLite cannot hide corrupted disk bytes.")
        } catch DocumentProcessingError.corruptedOriginal {
            // Expected; missing or corrupted original is never treated as a duplicate.
        }
        XCTAssertEqual(try Data(contentsOf: source), bytes)

        try FileManager.default.removeItem(at: stored)
        do {
            _ = try await store.importPDF(source, into: transaction)
            XCTFail("A missing original cannot be declared a duplicate.")
        } catch DocumentProcessingError.corruptedOriginal {}

        try bytes.write(to: stored)
        guard case .duplicate(let previous) = try await store.importPDF(
            source, into: transaction
        ) else { return XCTFail("After restoring the original, duplicate detection must work.") }
        XCTAssertEqual(previous.id, original.id)
        let records = try await store.documents(for: transaction)
        XCTAssertEqual(records.count, 1)
        XCTAssertTrue(stagingFiles(root: root, transactionID: transaction).isEmpty)
    }

    func testNonWritableDestinationReturnsStorageErrorAndRetrySucceeds() async throws {
        if Darwin.geteuid() == 0 {
            throw XCTSkip("Permission-denial test requires a non-root macOS process.")
        }
        let root = try root()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("write.pdf")
        try createDigitalPDF(source)
        let bytes = try Data(contentsOf: source)
        let store = try workspace(root)
        let transaction = UUID()
        let destination = root.appendingPathComponent("originals")
            .appendingPathComponent(transaction.uuidString)
        try FileManager.default.createDirectory(
            at: destination, withIntermediateDirectories: true
        )
        XCTAssertEqual(Darwin.chmod(destination.path, 0o500), 0)
        defer { _ = Darwin.chmod(destination.path, 0o700) }
        do {
            _ = try await store.importPDF(source, into: transaction)
            XCTFail("Import into non-writable directory must not succeed.")
        } catch DocumentProcessingError.storage {
            // Distinguish local disk write failure from an invalid PDF.
        }
        let afterFailure = try await store.documents(for: transaction)
        XCTAssertTrue(afterFailure.isEmpty)
        XCTAssertTrue(stagingFiles(root: root, transactionID: transaction).isEmpty)
        XCTAssertEqual(try Data(contentsOf: source), bytes)
        XCTAssertEqual(Darwin.chmod(destination.path, 0o700), 0)
        guard case .imported = try await store.importPDF(source, into: transaction)
        else { return XCTFail("Writable-directory retry should succeed.") }
        let afterRetry = try await store.documents(for: transaction)
        XCTAssertEqual(afterRetry.count, 1)
    }

    func testDeniedSourceReadDoesNotCreateRecordsThenRestores() async throws {
        if Darwin.geteuid() == 0 {
            throw XCTSkip("Permission-denial test requires a non-root macOS process.")
        }
        let root = try root()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("unreadable.pdf")
        try createDigitalPDF(source)
        let before = try Data(contentsOf: source)
        let store = try workspace(root)
        let transaction = UUID()
        XCTAssertEqual(Darwin.chmod(source.path, 0o000), 0)
        defer { _ = Darwin.chmod(source.path, 0o600) }
        do {
            _ = try await store.importPDF(source, into: transaction)
            XCTFail("Import must not succeed on a source whose read access is denied.")
        } catch {
            // FileHandle throws the operating-system permission error before copy.
            XCTAssertFalse(error is CancellationError)
        }
        let missing = try await store.documents(for: transaction)
        XCTAssertTrue(missing.isEmpty)
        XCTAssertTrue(stagingFiles(root: root, transactionID: transaction).isEmpty)
        XCTAssertEqual(Darwin.chmod(source.path, 0o600), 0)
        XCTAssertEqual(try Data(contentsOf: source), before)
        guard case .imported = try await store.importPDF(source, into: transaction)
        else { return XCTFail("Readable-source retry should succeed.") }
        let restored = try await store.documents(for: transaction)
        XCTAssertEqual(restored.count, 1)
    }
}
