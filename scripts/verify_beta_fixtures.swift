// Validate generated PDF page text with Apple's actual PDFKit in macOS CI.
// Synthetic examples do not establish real-estate OCR accuracy.
import Foundation
import PDFKit

guard CommandLine.arguments.count == 2 else {
    fputs("usage: swift verify_beta_fixtures.swift FIXTURE_FOLDER\n", stderr)
    exit(2)
}
let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let expectations: [(file: String, pages: Int, index: Int, line: String)] = [
    ("01-Accepted-Offer-Sample.pdf", 3, 1, "Acceptance Date: 2026-11-20"),
    ("01-Accepted-Offer-Sample.pdf", 3, 2, "Closing Date: 2026-12-21"),
    ("02-Conflicting-Facts-Sample.pdf", 2, 0, "Purchase Price: $675,000.00"),
    ("02-Conflicting-Facts-Sample.pdf", 2, 1, "Closing Date: 2026-12-28"),
    ("03-Unknown-Fields-Sample.pdf", 2, 0, "Acceptance Date: TBD")
]
for expectation in expectations {
    let url = folder.appendingPathComponent(expectation.file)
    guard let pdf = PDFDocument(url: url),
          pdf.pageCount == expectation.pages,
          let extracted = pdf.page(at: expectation.index)?.string,
          extracted.contains(expectation.line) else {
        fputs("BETA_FIXTURE_FAILURE \(expectation.file) page \(expectation.index + 1): \(expectation.line)\n", stderr)
        exit(1)
    }
}
print("BETA_PDFKIT_FIXTURES_PASS files=3 pages=7 checks=\(expectations.count)")
