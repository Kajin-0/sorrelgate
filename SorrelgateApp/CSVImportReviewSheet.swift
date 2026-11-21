import SorrelgateCore
import SwiftUI

/// Shared CSV/XLSX review. Every column assignment is explicit. No office
/// database mutation happens here: approval populates an unsaved editor draft.
struct CSVImportReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let table: CSVChecklistTable
    let onUse: ([OfficeTaskSpec]) -> Void

    @State private var titleColumn = 0
    @State private var requirementColumn: Int?
    @State private var notesColumn: Int?

    private func labelForColumn(_ index: Int) -> String {
        let header = table.headers[index]
        return "\(index + 1): \(header.isEmpty ? "Column \(index + 1)" : header)"
    }

    private var mappingError: String? {
        let mapped = [titleColumn, requirementColumn, notesColumn].compactMap { $0 }
        if Set(mapped).count != mapped.count {
            return "Each task field must use a different source column."
        }
        return nil
    }

    private var reviewed: CSVChecklistReview? {
        guard mappingError == nil else { return nil }
        return try? CSVChecklistImporter.review(
            table, mapping: CSVChecklistMapping(
                titleColumn: titleColumn,
                requirementColumn: requirementColumn,
                notesColumn: notesColumn
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Checklist Import").font(.title2.weight(.semibold))
            Text("Choose columns explicitly. Optional fields are not inferred. Changes go to an unsaved office draft; a separate Save creates the revision.")
                .foregroundStyle(.secondary)

            Picker("Task description column", selection: $titleColumn) {
                ForEach(table.headers.indices, id: \.self) { index in
                    Text(labelForColumn(index)).tag(index)
                }
            }
            Picker("Office requirement column", selection: $requirementColumn) {
                Text("Not mapped (Unspecified)").tag(nil as Int?)
                ForEach(table.headers.indices, id: \.self) { index in
                    Text(labelForColumn(index)).tag(Optional(index))
                }
            }
            Picker("Task notes column", selection: $notesColumn) {
                Text("Not mapped (empty notes)").tag(nil as Int?)
                ForEach(table.headers.indices, id: \.self) { index in
                    Text(labelForColumn(index)).tag(Optional(index))
                }
            }
            Text("Accepted requirement values: Required / Optional / Unspecified or Yes / No (also True / False, 1 / 0). Blank means Unspecified. Other values block import.")
                .font(.caption).foregroundStyle(.secondary)
            if let mappingError {
                Text(mappingError).foregroundStyle(.red)
            }
            if let reviewed {
                HStack(spacing: 18) {
                    Label("\(reviewed.tasks.count) valid tasks", systemImage: "checkmark.circle")
                    if !reviewed.issues.isEmpty {
                        Label("\(reviewed.issues.count) issues", systemImage: "exclamationmark.triangle")
                    }
                    Spacer()
                    Text("\(table.rows.count) source rows")
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                List {
                    Section("Sample source rows (first 30)") {
                        ForEach(Array(table.rows.prefix(30)), id: \.sourceLine) { row in
                            HStack(alignment: .top) {
                                Text("Row \(row.sourceLine)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(row.cells.indices.contains(titleColumn)
                                         ? row.cells[titleColumn] : "Missing task column")
                                        .textSelection(.enabled)
                                    if let column = requirementColumn,
                                       row.cells.indices.contains(column) {
                                        Text("Requirement: \(row.cells[column].isEmpty ? "Unspecified" : row.cells[column])")
                                            .font(.caption).foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                    }
                                    if let column = notesColumn,
                                       row.cells.indices.contains(column) {
                                        Text("Notes: \(row.cells[column])")
                                            .font(.caption).foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                    }
                                }
                            }
                        }
                    }
                    if !reviewed.issues.isEmpty {
                        Section("All issues — import blocked until corrected") {
                            ForEach(Array(reviewed.issues.enumerated()), id: \.offset) { pair in
                                Text("Source row \(pair.element.sourceLine): \(pair.element.detail)")
                                    .foregroundStyle(.red)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
                Text("No invalid rows are silently omitted. Correct the source file and retry. Approving replaces the current unsaved draft, not existing transactions.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                    Spacer()
                    Button("Use \(reviewed.tasks.count) Reviewed Tasks") {
                        onUse(reviewed.tasks)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!reviewed.issues.isEmpty || reviewed.tasks.isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(24)
        .frame(width: 800, height: 740)
    }
}
