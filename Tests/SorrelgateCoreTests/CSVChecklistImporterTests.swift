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
}
