import Foundation
import XCTest
import ZIPFoundation
@testable import SorrelgateCore

final class XLSXChecklistImporterTests: XCTestCase {
    private let xmlHeader = #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>"#

    private func fixture(
        formula: Bool = true, metadata: Bool = false, badRequirement: Bool = false
    ) throws -> Data {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sorrelgate-xlsx-" + UUID().uuidString)
        try FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: dir) }
        let zipURL = dir.appendingPathComponent("workbook.xlsx")
        let archive = try Archive(url: zipURL, accessMode: .create)

        let contentTypes = xmlHeader + #"""
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Default Extension="xml" ContentType="application/xml"/>
        <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
        <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
        <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
        <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
        </Types>
        """#
        let rootRels = xmlHeader + #"""
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
        """#
        let workbook = xmlHeader + #"""
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <sheets><sheet name="Accepted Offer" sheetId="1" r:id="rId1"/>
        <sheet name="Formula Review" sheetId="2" r:id="rId2"/></sheets>
        </workbook>
        """#
        let workbookRels = xmlHeader + #"""
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
        <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
        <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
        </Relationships>
        """#
        let sharedStrings = xmlHeader + #"""
        <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="6" uniqueCount="6">
        <si><t>Phase</t></si><si><t>Task</t></si><si><t>Receive agreement</t></si>
        <si><t>Review signatures</t></si><si><t>Notes</t></si><si><t>Other</t></si>
        </sst>
        """#
        let legacySheet = xmlHeader + #"""
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <sheetData>
        <row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c></row>
        <row r="2"><c r="A2" t="inlineStr"><is><t>Accepted</t></is></c>
        <c r="B2" t="s"><v>2</v></c></row>
        <row r="4"><c r="A4" t="inlineStr"><is><t>Review</t></is></c>
        <c r="B4" t="s"><v>3</v></c></row>
        </sheetData></worksheet>
        """#
        let requirement = badRequirement ? "Maybe" : "Yes"
        let metadataSheet = xmlHeader + """
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <sheetData>
        <row r="1"><c r="A1" t="inlineStr"><is><t>Notes</t></is></c>
        <c r="B1" t="inlineStr"><is><t>Task</t></is></c>
        <c r="C1" t="inlineStr"><is><t>Office required</t></is></c></row>
        <row r="2"><c r="A2" t="inlineStr"><is><t>Seller call</t></is></c>
        <c r="B2" t="s"><v>2</v></c>
        <c r="C2" t="inlineStr"><is><t>\(requirement)</t></is></c></row>
        <row r="4"><c r="A4" t="inlineStr"><is><t>Office optional</t></is></c>
        <c r="B4" t="s"><v>3</v></c>
        <c r="C4" t="inlineStr"><is><t>No</t></is></c></row>
        </sheetData></worksheet>
        """
        let sheet1 = metadata ? metadataSheet : legacySheet
        let formulaCell = formula
            ? #"<c r="A2" t="str"><f>HYPERLINK("https://example.invalid","unsafe")</f><v>unsafe</v></c>"#
            : #"<c r="A2" t="inlineStr"><is><t>Verify title</t></is></c>"#
        let sheet2 = xmlHeader + """
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <sheetData><row r="1"><c r="A1" t="s"><v>1</v></c>
        <c r="B1" t="s"><v>4</v></c></row>
        <row r="2">\(formulaCell)<c r="B2" t="s"><v>5</v></c></row>
        </sheetData></worksheet>
        """

        let entries: [(String, String)] = [
            ("[Content_Types].xml", contentTypes),
            ("_rels/.rels", rootRels),
            ("xl/workbook.xml", workbook),
            ("xl/_rels/workbook.xml.rels", workbookRels),
            ("xl/sharedStrings.xml", sharedStrings),
            ("xl/worksheets/sheet1.xml", sheet1),
            ("xl/worksheets/sheet2.xml", sheet2)
        ]
        for (path, xml) in entries {
            let bytes = Data(xml.utf8)
            try archive.addEntry(
                with: path, type: .file,
                uncompressedSize: Int64(bytes.count),
                compressionMethod: .deflate,
                provider: { offset, size in
                    let start = Int(offset)
                    return bytes.subdata(in: start..<min(start + size, bytes.count))
                }
            )
        }
        return try Data(contentsOf: zipURL)
    }

    func testNamedSheetsAndSparseRowsShareCSVReviewContract() throws {
        let workbook = try XLSXChecklistImporter.parse(fixture())
        XCTAssertEqual(workbook.sheets.count, 2)
        XCTAssertEqual(workbook.sheets[0].name, "Accepted Offer")
        let table = workbook.sheets[0].table
        XCTAssertEqual(table.headers, ["Phase", "Task"])
        XCTAssertEqual(table.rows.map(\.sourceLine), [2, 4])
        let review = try CSVChecklistImporter.review(table, titleColumn: 1)
        XCTAssertTrue(review.issues.isEmpty)
        XCTAssertEqual(review.titles, ["Receive agreement", "Review signatures"])
    }

    func testFormulaCellsAreFlaggedAndCannotBeApproved() throws {
        let workbook = try XLSXChecklistImporter.parse(fixture())
        let review = try CSVChecklistImporter.review(
            workbook.sheets[1].table, titleColumn: 0
        )
        XCTAssertEqual(review.issues.count, 1)
        XCTAssertEqual(review.issues.first?.sourceLine, 2)
        XCTAssertTrue(review.issues.first?.detail.contains("Formula") == true)
    }

    func testPlainTextCellOnSecondSheetIsReviewable() throws {
        let workbook = try XLSXChecklistImporter.parse(fixture(formula: false))
        let review = try CSVChecklistImporter.review(
            workbook.sheets[1].table, titleColumn: 0
        )
        XCTAssertTrue(review.issues.isEmpty)
        XCTAssertEqual(review.titles, ["Verify title"])
    }

    func testMalformedAndOversizeWorkbookAreRejected() throws {
        XCTAssertThrowsError(try XLSXChecklistImporter.parse(Data([0x01,0x02])))
        XCTAssertThrowsError(try XLSXChecklistImporter.parse(
            Data(repeating: 42, count: XLSXChecklistImporter.byteLimit + 1)
        ))
    }
    func testRealXLSXMetadataMappingWithSparsePhysicalRows() throws {
        let workbook = try XLSXChecklistImporter.parse(fixture(metadata: true))
        let table = workbook.sheets[0].table
        XCTAssertEqual(table.headers, ["Notes", "Task", "Office required"])
        XCTAssertEqual(table.rows.map(\.sourceLine), [2, 4])
        let review = try CSVChecklistImporter.review(
            table, mapping: CSVChecklistMapping(
                titleColumn: 1, requirementColumn: 2, notesColumn: 0
            )
        )
        XCTAssertTrue(review.issues.isEmpty)
        XCTAssertEqual(review.titles, ["Receive agreement", "Review signatures"])
        XCTAssertEqual(review.tasks.map(\.requirement), [.required, .optional])
        XCTAssertEqual(review.tasks.map(\.notes), ["Seller call", "Office optional"])
    }

    func testInvalidMappedXLSXRequirementBlocksApprovalWithSourceRow() throws {
        let workbook = try XLSXChecklistImporter.parse(
            fixture(metadata: true, badRequirement: true)
        )
        let review = try CSVChecklistImporter.review(
            workbook.sheets[0].table,
            mapping: CSVChecklistMapping(
                titleColumn: 1, requirementColumn: 2, notesColumn: 0
            )
        )
        XCTAssertEqual(review.issues.count, 1)
        XCTAssertEqual(review.issues[0].sourceLine, 2)
        XCTAssertTrue(review.issues[0].detail.contains("Maybe"))
        XCTAssertEqual(review.tasks.count, 1)
        XCTAssertEqual(review.tasks[0].title, "Review signatures")
        // The UI refuses "Use" while ANY issue exists: no subset is applied.
    }

}
