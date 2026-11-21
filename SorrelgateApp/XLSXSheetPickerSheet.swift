import SorrelgateCore
import SwiftUI

/// A workbook may contain unrelated worksheets. The user must explicitly
/// choose the one whose task descriptions they intend to import.
struct XLSXSheetPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let workbook: XLSXChecklistWorkbook
    let onUse: ([String]) -> Void

    @State private var selectedID: UUID?
    @State private var reviewTable: CSVChecklistTable?

    private var selectedSheet: XLSXChecklistSheet? {
        workbook.sheets.first { $0.id == selectedID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose an Excel Worksheet").font(.title2.weight(.semibold))
            Text("Sorrelgate reads the selected sheet only. Your Excel file is never modified.")
                .foregroundStyle(.secondary)
            Picker("Worksheet", selection: $selectedID) {
                Text("Choose a worksheet").tag(nil as UUID?)
                ForEach(workbook.sheets) { sheet in
                    Text(sheet.name).tag(Optional(sheet.id))
                }
            }
            if let selectedSheet {
                Text("Source rows: \(selectedSheet.table.rows.count)")
                    .font(.callout)
                Text("Next, choose the column containing task descriptions and review any invalid rows.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack {
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Review Selected Worksheet") {
                    reviewTable = selectedSheet?.table
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedSheet == nil)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 530, height: 260)
        .onAppear {
            if selectedID == nil { selectedID = workbook.sheets.first?.id }
        }
        .sheet(item: $reviewTable) { table in
            CSVImportReviewSheet(table: table) { titles in
                onUse(titles)
                dismiss()
            }
        }
    }
}
