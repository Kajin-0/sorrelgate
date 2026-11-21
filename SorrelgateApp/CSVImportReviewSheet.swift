import SorrelgateCore
import SwiftUI

/// Shared CSV/XLSX review. Column mapping never mutates saved office data.
/// Cancel remains available even when the mapping or review is invalid.
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

    /// Errors must not be silently erased with try?. An invalid mapping is a
    /// review state, not a reason to hide the exit controls.
    private var reviewResult: Result<CSVChecklistReview, Error> {
        Result {
            try CSVChecklistImporter.review(
                table, mapping: CSVChecklistMapping(
                    titleColumn: titleColumn,
                    requirementColumn: requirementColumn,
                    notesColumn: notesColumn
                )
            )
        }
    }

    var body: some View {
        let outcome = reviewResult
        let reviewed: CSVChecklistReview? = {
            if case .success(let value) = outcome { return value }
            return nil
        }()
        let reviewError: String? = {
            if case .failure(let error) = outcome { return error.localizedDescription }
            return nil
        }()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Review Checklist Import").font(.title2.weight(.semibold))
            Text("Choose the columns for task descriptions and optional details. Review any problems before using the tasks.")
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
            Text("Requirement values: Required, Optional, Unspecified, Yes/No, True/False, or 1/0. Leave blank for Unspecified.")
                .font(.caption).foregroundStyle(.secondary)

            if let reviewError {
                Label(reviewError, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .accessibilityAddTraits(.isStaticText)
            }

            if let reviewed {
                HStack(spacing: 18) {
                    Label("\(reviewed.tasks.count) valid tasks", systemImage: "checkmark.circle")
                    if !reviewed.issues.isEmpty {
                        Label("\(reviewed.issues.count) issues to fix",
                              systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    Text("\(table.rows.count) source rows")
                        .foregroundStyle(.secondary)
                }
                .font(.callout)

                // Blockers are visible above the samples and before scrolling.
                if !reviewed.issues.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fix these problems in the source file before importing:")
                            .font(.callout.weight(.semibold))
                        ForEach(Array(reviewed.issues.prefix(3).enumerated()), id: \.offset) { item in
                            Text("Row \(item.element.sourceLine): \(item.element.detail)")
                                .font(.callout)
                                .textSelection(.enabled)
                        }
                        if reviewed.issues.count > 3 {
                            Text("And \(reviewed.issues.count - 3) more below.")
                                .font(.callout)
                        }
                    }
                    .foregroundStyle(.red)
                }

                List {
                    if !reviewed.issues.isEmpty {
                        Section("All problems — import unavailable") {
                            ForEach(Array(reviewed.issues.enumerated()), id: \.offset) { pair in
                                Text("Row \(pair.element.sourceLine): \(pair.element.detail)")
                                    .textSelection(.enabled)
                            }
                        }
                    }
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
                }
                Text("No problem rows are silently omitted. This replaces only the unsaved office draft, not existing transactions.")
                    .font(.caption).foregroundStyle(.secondary)
            } else if reviewError == nil {
                Text("Choose a valid column mapping to review the imported tasks.")
                    .foregroundStyle(.secondary)
            }

            // Never put Cancel inside a successful-review conditional.
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Use \(reviewed?.tasks.count ?? 0) Reviewed Tasks") {
                    guard let reviewed, reviewed.issues.isEmpty,
                          !reviewed.tasks.isEmpty else { return }
                    onUse(reviewed.tasks)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(reviewed?.issues.isEmpty != true || reviewed?.tasks.isEmpty != false)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 800, height: 740)
    }
}
