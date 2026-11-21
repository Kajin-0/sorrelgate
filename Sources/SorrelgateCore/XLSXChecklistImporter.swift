import CoreXLSX
import Foundation
import ZIPFoundation

public struct XLSXChecklistSheet: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let table: CSVChecklistTable
}

public struct XLSXChecklistWorkbook: Identifiable, Sendable {
    public let id: UUID
    public let sheets: [XLSXChecklistSheet]
}

public enum XLSXChecklistError: Error, LocalizedError {
    case tooLarge
    case expansionLimit
    case unreadable
    case noSheets
    case tooManySheets
    case tooManyRows
    case tooManyColumns
    case noHeaders
    case invalidSharedString

    public var errorDescription: String? {
        switch self {
        case .tooLarge: "Select an XLSX file smaller than 2 MB."
        case .expansionLimit: "The XLSX archive expands beyond the safe 24 MB processing limit."
        case .unreadable: "The spreadsheet could not be read. Check that it is an unencrypted .xlsx file."
        case .noSheets: "The workbook has no worksheets."
        case .tooManySheets: "This workbook exceeds the 20-sheet import limit."
        case .tooManyRows: "A worksheet exceeds 2,000 task rows."
        case .tooManyColumns: "A worksheet exceeds 64 columns."
        case .noHeaders: "A worksheet has no usable header row."
        case .invalidSharedString: "A cell contains an invalid shared-string reference."
        }
    }
}

/// Read-only XLSX ingestion. No formulas are evaluated, and no source file
/// is changed. Every sheet becomes the same review model used by CSV imports.
public enum XLSXChecklistImporter {
    public static let byteLimit = 2 * 1024 * 1024
    public static let expansionLimit: UInt64 = 24 * 1024 * 1024

    public static func parse(_ data: Data) throws -> XLSXChecklistWorkbook {
        guard data.count <= byteLimit else { throw XLSXChecklistError.tooLarge }
        guard let archive = Archive(data: data, accessMode: .read) else {
            throw XLSXChecklistError.unreadable
        }

        var expanded: UInt64 = 0
        var entryCount = 0
        for entry in archive {
            entryCount += 1
            guard entryCount <= 200, entry.uncompressedSize <= expansionLimit,
                  expanded <= expansionLimit - entry.uncompressedSize else {
                throw XLSXChecklistError.expansionLimit
            }
            expanded += entry.uncompressedSize
        }

        let file: XLSXFile
        do {
            file = try XLSXFile(data: data)
        } catch {
            throw XLSXChecklistError.unreadable
        }
        let books: [Workbook]
        do {
            books = try file.parseWorkbooks()
        } catch {
            throw XLSXChecklistError.unreadable
        }
        guard let first = books.first else { throw XLSXChecklistError.noSheets }
        let paths: [(name: String?, path: String)]
        do {
            paths = try file.parseWorksheetPathsAndNames(workbook: first)
        } catch {
            throw XLSXChecklistError.unreadable
        }
        guard !paths.isEmpty else { throw XLSXChecklistError.noSheets }
        guard paths.count <= 20 else { throw XLSXChecklistError.tooManySheets }

        let sharedStrings: SharedStrings?
        do {
            sharedStrings = try file.parseSharedStrings()
        } catch {
            throw XLSXChecklistError.unreadable
        }

        var result: [XLSXChecklistSheet] = []
        for (position, entry) in paths.enumerated() {
            let sheet: Worksheet
            do {
                sheet = try file.parseWorksheet(at: entry.path)
            } catch {
                throw XLSXChecklistError.unreadable
            }
            let rows = try convertRows(sheet.data?.rows ?? [], sharedStrings: sharedStrings)
            let name = entry.name ?? "Sheet \(position + 1)"
            result.append(XLSXChecklistSheet(
                id: UUID(), name: name,
                table: try makeReviewTable(from: rows)
            ))
        }
        return XLSXChecklistWorkbook(id: UUID(), sheets: result)
    }

    /// Keep physical Excel row numbers and sparse cell positions for auditing.
    /// A malformed or formula-derived cell is review-blocking, not executed.
    private static func convertRows(
        _ input: [CoreXLSX.Row], sharedStrings: SharedStrings?
    ) throws -> [(line: Int, values: [Int: String], issues: [CSVChecklistIssue])] {
        guard input.count <= 2_001 else { throw XLSXChecklistError.tooManyRows }
        var result: [(line: Int, values: [Int: String], issues: [CSVChecklistIssue])] = []
        for row in input {
            guard row.reference > 0, row.reference <= 1_000_000 else {
                throw XLSXChecklistError.tooManyRows
            }
            let rowNumber = Int(row.reference)
            var values: [Int: String] = [:]
            var issues: [CSVChecklistIssue] = []
            for cell in row.cells {
                let column = try columnIndex(cell.reference.column.value)
                let text = try decodedValue(cell, strings: sharedStrings)
                if cell.formula != nil || cell.type == .error {
                    issues.append(CSVChecklistIssue(
                        sourceLine: rowNumber,
                        detail: "Formula or spreadsheet error at \(cell.reference). Replace with plain text."
                    ))
                }
                if values.updateValue(text, forKey: column) != nil {
                    issues.append(CSVChecklistIssue(
                        sourceLine: rowNumber,
                        detail: "Duplicate cell position \(cell.reference)."
                    ))
                }
            }
            if values.values.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
               issues.isEmpty { continue }
            result.append((line: rowNumber, values: values, issues: issues))
        }
        guard result.count <= 2_001 else { throw XLSXChecklistError.tooManyRows }
        return result
    }

    private static func columnIndex(_ name: String) throws -> Int {
        var index = 0
        for scalar in name.unicodeScalars {
            guard scalar.value >= 65, scalar.value <= 90 else {
                throw XLSXChecklistError.tooManyColumns
            }
            index = index * 26 + Int(scalar.value - 64)
            guard index <= 64 else { throw XLSXChecklistError.tooManyColumns }
        }
        guard index > 0 else { throw XLSXChecklistError.tooManyColumns }
        return index - 1
    }

    private static func decodedValue(
        _ cell: Cell, strings: SharedStrings?
    ) throws -> String {
        if cell.type == .sharedString {
            guard let indexText = cell.value, let index = Int(indexText),
                  let items = strings?.items, items.indices.contains(index) else {
                throw XLSXChecklistError.invalidSharedString
            }
            let item = items[index]
            return item.text ?? item.richText.compactMap(\.text).joined()
        }
        return cell.inlineString?.text ?? cell.value ?? ""
    }

    private static func makeReviewTable(
        from rows: [(line: Int, values: [Int: String], issues: [CSVChecklistIssue])]
    ) throws -> CSVChecklistTable {
        guard let first = rows.first else { throw XLSXChecklistError.noHeaders }
        let width = (first.values.keys.max() ?? -1) + 1
        guard width > 0 else { throw XLSXChecklistError.noHeaders }
        guard width <= 64 else { throw XLSXChecklistError.tooManyColumns }
        let headers = (0..<width).map { first.values[$0] ?? "" }
        let remaining = rows.dropFirst()
        let records = remaining.map { row -> CSVChecklistRow in
            let length = max(width, (row.values.keys.max() ?? -1) + 1)
            return CSVChecklistRow(
                sourceLine: row.line,
                cells: (0..<length).map { row.values[$0] ?? "" }
            )
        }
        let issues = rows.flatMap(\.issues)
        return CSVChecklistTable(
            id: UUID(), headers: headers, rows: records, importIssues: issues
        )
    }
}
