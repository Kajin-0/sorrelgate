import SorrelgateCore
import SwiftUI

/// Edits only the checklist row. Original PDF bytes are never touched.
struct EditTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var confirmRemoval = false
    let task: ChecklistItem
    let onSave: (String) -> Void
    let onRemove: () -> Void

    init(task: ChecklistItem, onSave: @escaping (String) -> Void,
         onRemove: @escaping () -> Void) {
        self.task = task
        self.onSave = onSave
        self.onRemove = onRemove
        _title = State(initialValue: task.title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Checklist Task").font(.title2.weight(.semibold))
            TextField("Task description", text: $title)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Checklist task")
            Text("Editing or removing this task will not delete its linked PDF.")
                .font(.callout).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            HStack {
                Button("Remove Task", role: .destructive) { confirmRemoval = true }
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save") { onSave(title); dismiss() }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460, height: 230)
        .confirmationDialog("Remove this task?", isPresented: $confirmRemoval) {
            Button("Remove Task", role: .destructive) {
                onRemove()
                dismiss()
            }
            Button("Keep Task", role: .cancel) {}
        } message: {
            Text("The original PDF and all other tasks remain unchanged.")
        }
    }
}
