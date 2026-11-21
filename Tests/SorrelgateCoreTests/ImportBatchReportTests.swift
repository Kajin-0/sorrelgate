import XCTest
@testable import SorrelgateCore

final class ImportBatchReportTests: XCTestCase {
    func testMixedSuccessDuplicateAndFailureAlwaysReported() {
        let report = ImportBatchReport(
            imported: 5, alreadyPresent: 2, failed: 3, cancelled: false
        )
        XCTAssertEqual(
            report.summary,
            "Imported 5 PDFs. 2 already imported. 3 couldn't be imported."
        )
    }

    func testCancelledImportRetainsCompletedCounts() {
        let report = ImportBatchReport(
            imported: 1, alreadyPresent: 0, failed: 0, cancelled: true
        )
        XCTAssertEqual(
            report.summary,
            "Imported 1 PDF. Import stopped. Completed PDFs were kept."
        )
    }

    func testFailureFilenameNotDuplicatedAndOmittedCountIsVisible() {
        XCTAssertEqual(
            ImportBatchReport.failure(
                filename: "scan.pdf", reason: "Could not open 'scan.pdf' as a valid PDF."
            ),
            "Could not open 'scan.pdf' as a valid PDF."
        )
        XCTAssertEqual(
            ImportBatchReport.failure(
                filename: "not-readable.pdf", reason: "Permission denied"
            ),
            "not-readable.pdf: Permission denied"
        )
        let failures = (1...7).map { "Problem \($0)" }
        let text = ImportBatchReport.conciseFailures(failures)
        XCTAssertTrue(text.contains("Problem 4"))
        XCTAssertFalse(text.contains("Problem 5"))
        XCTAssertTrue(text.contains("And 3 more errors."))
    }
}
