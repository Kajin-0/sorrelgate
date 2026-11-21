import SorrelgateCore
import SwiftUI

/// Read-only CSV inspection. Applying copies approved task names into the
/// office editor's unsaved draft; a separate Save creates the next revision.
struct CSVImportReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let table: CSVChecklistTable
    let onUse: ([String]) -> Void
    @State private var titleColumn = 0

    private var reviewed: CSVChecklistReview? {
        try? CSVChecklistImporter.review(table, titleColumn: titleColumn)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Review CSV Checklist").font(.title2.weight(.semibold))
            Text("Choose the column containing task descriptions. No changes are saved until you review and save the office checklist.")
                .foregroundStyle(.secondary)
            Picker("Task description column", selection: $titleColumn) {
                ForEach(table.headers.indices, id: \.self) { index in
                    let name = table.headers[index].isEmpty
                        ? "Column \(index + 1)"
                        : table.headers[index]
                    Text("\(index + 1): \(name)").tag(index)
                }
            }
            if let reviewed {
                HStack(spacing: 18) {
                    Label("\(reviewed.titles.count) valid tasks", systemImage: "checkmark.circle")
                    if !reviewed.issues.isEmpty {
                        Label("\(reviewed.issues.count) rows need review", systemImage: "exclamationmark.triangle")
                    }
                    Spacer()
                    Text("\(table.rows.count) source rows")
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                List {
                    Section("Sample rows (first 30)") {
                        ForEach(Array(table.rows.prefix(30)), id: \.sourceLine) { row in
                            HStack(alignment: .top) {
                                Text("Line \(row.sourceLine)").font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary).frame(width: 80, alignment: .leading)
                                Text(row.cells.indices.contains(titleColumn)
                                     ? row.cells[titleColumn] : "Missing mapped column")
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    if !reviewed.issues.isEmpty {
                        Section("Rows requiring correction — import blocked") {
                            ForEach(Array(reviewed.issues.prefix(50).enumerated()), id: \.offset) { _, issue in
                                Text("Line \(issue.sourceLine): \(issue.detail)")
                                    .foregroundStyle(.red)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
                Text("Invalid rows are never silently discarded. Fix the CSV and import it again.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                    Spacer()
                    Button("Use \(reviewed.titles.count) Reviewed Tasks") {
                        onUse(reviewed.titles)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!reviewed.issues.isEmpty || reviewed.titles.isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(24)
        .frame(width: 760, height: 630)
    }
}
