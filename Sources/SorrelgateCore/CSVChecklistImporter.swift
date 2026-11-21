import Foundation

public struct CSVChecklistRow: Sendable {
    public let sourceLine: Int
    public let cells: [String]
}

public struct CSVChecklistTable: Identifiable, Sendable {
    public let id: UUID
    public let headers: [String]
    public let rows: [CSVChecklistRow]
}

public struct CSVChecklistIssue: Sendable {
    public let sourceLine: Int
    public let detail: String
}

public struct CSVChecklistReview: Sendable {
    public let titles: [String]
    public let issues: [CSVChecklistIssue]
}

public enum CSVChecklistImportError: Error, LocalizedError {
    case unsupportedEncoding
    case tooLarge
    case malformed(Int)
    case empty
    case tooManyRows
    case tooManyColumns
    case invalidColumn

    public var errorDescription: String? {
        switch self {
        case .unsupportedEncoding: "Use a CSV file saved as UTF-8 (including UTF-8 with BOM)."
        case .tooLarge: "This CSV exceeds the 2 MB import limit."
        case .malformed(let line): "Invalid CSV quotation near line \(line)."
        case .empty: "The CSV must contain a header row and at least one task row."
        case .tooManyRows: "This CSV contains over 2,000 rows. Split the import into smaller files."
        case .tooManyColumns: "The CSV contains over 64 columns."
        case .invalidColumn: "Choose a valid column containing task descriptions."
        }
    }
}

/// RFC-4180-style UTF-8 CSV parser with explicit review: nothing in this
/// utility mutates an office, transaction or original document.
public enum CSVChecklistImporter {
    public static let byteLimit = 2 * 1024 * 1024

    public static func parse(_ data: Data) throws -> CSVChecklistTable {
        guard data.count <= byteLimit else { throw CSVChecklistImportError.tooLarge }
        guard var text = String(data: data, encoding: .utf8) else {
            throw CSVChecklistImportError.unsupportedEncoding
        }
        if text.first == "\u{FEFF}" { text.removeFirst() }
        let chars = Array(text)
        var records: [CSVChecklistRow] = []
        var fields: [String] = []
        var field = ""
        var quoted = false
        var closedQuote = false
        var atFieldStart = true
        var line = 1
        var rowStart = 1
        var cursor = 0

        func finishField() throws {
            fields.append(field)
            guard fields.count <= 64 else { throw CSVChecklistImportError.tooManyColumns }
            field = ""
            closedQuote = false
            atFieldStart = true
        }

        func finishRow() throws {
            try finishField()
            if !fields.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                records.append(CSVChecklistRow(sourceLine: rowStart, cells: fields))
                guard records.count <= 2_001 else { throw CSVChecklistImportError.tooManyRows }
            }
            fields = []
        }

        while cursor < chars.count {
            let char = chars[cursor]
            if quoted {
                if char == "\"" {
                    if cursor + 1 < chars.count && chars[cursor + 1] == "\"" {
                        field.append("\"")
                        cursor += 1
                    } else {
                        quoted = false
                        closedQuote = true
                    }
                } else {
                    field.append(char)
                    if char == "\n" || (char == "\r" &&
                        (cursor + 1 == chars.count || chars[cursor + 1] != "\n")) {
                        line += 1
                    }
                }
            } else if char == "," {
                try finishField()
            } else if char == "\r" || char == "\n" {
                try finishRow()
                if char == "\r" && cursor + 1 < chars.count && chars[cursor + 1] == "\n" {
                    cursor += 1
                }
                line += 1
                rowStart = line
            } else if char == "\"" {
                guard atFieldStart && !closedQuote else {
                    throw CSVChecklistImportError.malformed(line)
                }
                quoted = true
                atFieldStart = false
            } else if closedQuote {
                guard char == " " || char == "\t" else {
                    throw CSVChecklistImportError.malformed(line)
                }
            } else {
                field.append(char)
                atFieldStart = false
            }
            cursor += 1
        }
        guard !quoted else { throw CSVChecklistImportError.malformed(rowStart) }
        if !fields.isEmpty || !field.isEmpty || closedQuote {
            try finishRow()
        }
        guard records.count >= 2 else { throw CSVChecklistImportError.empty }
        let headers = records.removeFirst().cells.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return CSVChecklistTable(
            id: UUID(), headers: headers, rows: records
        )
    }

    /// A preview reports every invalid or unmatched row; there is deliberately
    /// no silent truncation, guessing or selective import of the valid subset.
    public static func review(
        _ table: CSVChecklistTable, titleColumn: Int
    ) throws -> CSVChecklistReview {
        guard table.headers.indices.contains(titleColumn) else {
            throw CSVChecklistImportError.invalidColumn
        }
        var titles: [String] = []
        var issues: [CSVChecklistIssue] = []
        var seen = Set<String>()
        for row in table.rows {
            if row.cells.count != table.headers.count {
                issues.append(CSVChecklistIssue(
                    sourceLine: row.sourceLine,
                    detail: "Expected \(table.headers.count) columns, found \(row.cells.count)."
                ))
                continue
            }
            let title = row.cells[titleColumn].trimmingCharacters(in: .whitespacesAndNewlines)
            if title.isEmpty || title.count > 250 || title.contains("\n") || title.contains("\r") {
                issues.append(CSVChecklistIssue(
                    sourceLine: row.sourceLine,
                    detail: "Task description must be one nonempty line of at most 250 characters."
                ))
                continue
            }
            let key = title.folding(
                options: [.caseInsensitive, .diacriticInsensitive], locale: nil
            )
            if !seen.insert(key).inserted {
                issues.append(CSVChecklistIssue(
                    sourceLine: row.sourceLine, detail: "Duplicate task: \(title)"
                ))
                continue
            }
            titles.append(title)
        }
        if titles.count > 100 {
            issues.append(CSVChecklistIssue(
                sourceLine: 0, detail: "Office templates support a maximum of 100 tasks."
            ))
        }
        return CSVChecklistReview(titles: titles, issues: issues)
    }
}
