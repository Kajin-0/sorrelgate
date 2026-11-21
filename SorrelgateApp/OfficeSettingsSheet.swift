import SorrelgateCore
import SwiftUI
import UniformTypeIdentifiers

/// Office configuration is an explicit user operation, not a global rewrite of
/// historical transactions. Existing transactions retain their checklist rows.
struct OfficeSettingsSheet: View {
    /// Stable identity avoids index-based bindings becoming stale after
    /// removing or moving an office task while a text field is active.
    private struct DraftTask: Identifiable {
        let id: UUID
        var task: OfficeTaskSpec
        init(_ task: OfficeTaskSpec) {
            self.id = UUID()
            self.task = task
        }
    }

    private enum Destination {
        case close
        case office(UUID?)
        case workflow(WorkflowKind)
    }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workspace: WorkspaceModel
    @State private var newOfficeName = ""
    @State private var isImportingCSV = false
    @State private var isImportingXLSX = false
    @State private var isReadingXLSX = false
    @State private var xlsxWorkbook: XLSXChecklistWorkbook?
    @State private var csvTable: CSVChecklistTable?
    @State private var selectedOfficeID: UUID?
    @State private var workflow: WorkflowKind = .acceptedOffer
    @State private var draftTasks: [DraftTask] = []
    @State private var savedTasks: [OfficeTaskSpec] = []
    @State private var revision = 0
    @State private var pendingDestination: Destination?
    @State private var showUnsavedConfirmation = false
    @State private var isWorking = false
    @State private var notice: String?
    @State private var errorMessage: String?

    private var isDirty: Bool {
        draftTasks.map(\.task) != savedTasks
    }

    private var templateKey: String {
        (selectedOfficeID?.uuidString ?? "none") + ":" + workflow.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Office Checklists").font(.title2.weight(.semibold))
                Spacer()
                Button("Done") { requestNavigation(.close) }
                    .keyboardShortcut(.cancelAction)
                    .disabled(isWorking)
            }
            Text("Each office has its own editable checklist. Changes apply only to new transactions.")
                .foregroundStyle(.secondary)
            HStack {
                TextField("New office name", text: $newOfficeName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("New office name")
                Button("Add Office") { createOffice() }
                    .disabled(isWorking || newOfficeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Picker("Office", selection: Binding(
                get: { selectedOfficeID },
                set: { requestNavigation(.office($0)) }
            )) {
                Text("Choose an office").tag(nil as UUID?)
                ForEach(workspace.offices) { office in
                    Text(office.name).tag(Optional(office.id))
                }
            }
            if selectedOfficeID != nil {
                Picker("Work type", selection: Binding(
                    get: { workflow },
                    set: { requestNavigation(.workflow($0)) }
                )) {
                    ForEach(WorkflowKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                HStack {
                    Text("Task order, office requirement, and notes").font(.headline)
                    Spacer()
                    if isDirty {
                        Label("Unsaved changes", systemImage: "pencil.circle")
                            .foregroundStyle(.orange)
                            .font(.callout)
                    }
                    Text("Revision \(revision)").font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                List {
                    ForEach($draftTasks) { $draft in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text("\((draftTasks.firstIndex(where: { $0.id == draft.id }) ?? 0) + 1)")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)
                                TextField("Task description", text: $draft.task.title)
                                    .accessibilityLabel("Task description")
                                Button {
                                    moveTask(draft.id, by: -1)
                                } label: {
                                    Image(systemName: "arrow.up")
                                }
                                .disabled(draftTasks.first?.id == draft.id)
                                .help("Move task up")
                                Button {
                                    moveTask(draft.id, by: 1)
                                } label: {
                                    Image(systemName: "arrow.down")
                                }
                                .disabled(draftTasks.last?.id == draft.id)
                                .help("Move task down")
                                Button {
                                    draftTasks.removeAll { $0.id == draft.id }
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .disabled(draftTasks.count <= 1)
                                .help("Remove task")
                            }
                            HStack {
                                Picker("Office requirement", selection: $draft.task.requirement) {
                                    ForEach(OfficeTaskRequirement.allCases, id: \.self) { level in
                                        Text(level.displayName).tag(level)
                                    }
                                }
                                .frame(width: 230)
                                TextField("Notes (optional)", text: $draft.task.notes)
                                    .accessibilityLabel("Task notes")
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .disabled(isWorking)
                HStack {
                    Button("Add Task") {
                        draftTasks.append(DraftTask(OfficeTaskSpec(title: "New task")))
                    }
                        .disabled(draftTasks.count >= 100 || isWorking)
                    Button("Import CSV") { isImportingCSV = true }
                        .disabled(isWorking)
                    Button("Import Excel") { isImportingXLSX = true }
                        .disabled(isWorking || isReadingXLSX)
                    if isReadingXLSX {
                        ProgressView().controlSize(.small)
                            .accessibilityLabel("Reading Excel workbook")
                    }
                    Spacer()
                    if let notice {
                        Text(notice).font(.caption).foregroundStyle(.secondary)
                    }
                    Button("Save Office Checklist") { saveTemplate() }
                        .buttonStyle(.borderedProminent)
                        .disabled(isWorking || draftTasks.isEmpty || !isDirty)
                }
            } else {
                ContentUnavailableView(
                    "No Office Selected",
                    systemImage: "building.2",
                    description: Text("Add an office to customize its seller-side workflows.")
                )
            }
        }
        .padding(24)
        .frame(width: 840, height: 660)
        .interactiveDismissDisabled(isDirty || isWorking)
        .confirmationDialog(
            "Save changes to this office checklist?",
            isPresented: $showUnsavedConfirmation,
            titleVisibility: .visible
        ) {
            Button("Save and Continue") {
                let next = pendingDestination
                pendingDestination = nil
                saveTemplate(afterSave: next)
            }
            Button("Discard Changes", role: .destructive) {
                draftTasks = savedTasks.map(DraftTask.init)
                if let next = pendingDestination { applyNavigation(next) }
                pendingDestination = nil
            }
            Button("Keep Editing", role: .cancel) {
                pendingDestination = nil
            }
        } message: {
            Text("Your edits have not been saved. You can save them, discard them, or keep editing.")
        }
        .fileImporter(
            isPresented: $isImportingCSV,
            allowedContentTypes: [.commaSeparatedText, .plainText]
        ) { result in
            switch result {
            case .success(let url):
                do {
                    let allowed = url.startAccessingSecurityScopedResource()
                    defer { if allowed { url.stopAccessingSecurityScopedResource() } }
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    if let size = attributes[.size] as? NSNumber,
                       size.intValue > CSVChecklistImporter.byteLimit {
                        throw CSVChecklistImportError.tooLarge
                    }
                    csvTable = try CSVChecklistImporter.parse(Data(contentsOf: url))
                } catch {
                    errorMessage = error.localizedDescription
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .sheet(item: $csvTable) { table in
            CSVImportReviewSheet(table: table) { imported in
                draftTasks = imported.map(DraftTask.init)
                notice = "Imported \(imported.count) tasks into this draft. Save to keep them."
            }
        }
        .fileImporter(
            isPresented: $isImportingXLSX,
            allowedContentTypes: [UTType(filenameExtension: "xlsx") ?? .data]
        ) { result in
            switch result {
            case .success(let url):
                do {
                    let allowed = url.startAccessingSecurityScopedResource()
                    defer { if allowed { url.stopAccessingSecurityScopedResource() } }
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    if let size = attributes[.size] as? NSNumber,
                       size.intValue > XLSXChecklistImporter.byteLimit {
                        throw XLSXChecklistError.tooLarge
                    }
                    let data = try Data(contentsOf: url)
                    isReadingXLSX = true
                    Task {
                        defer { isReadingXLSX = false }
                        do {
                            let workbook = try await Task.detached(
                                priority: .userInitiated
                            ) {
                                try XLSXChecklistImporter.parse(data)
                            }.value
                            xlsxWorkbook = workbook
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .sheet(item: $xlsxWorkbook) { workbook in
            XLSXSheetPickerSheet(workbook: workbook) { imported in
                draftTasks = imported.map(DraftTask.init)
                notice = "Imported \(imported.count) Excel tasks into this draft. Save to keep them."
            }
        }
        .task {
            await workspace.reloadOffices()
        }
        .task(id: templateKey) {
            await loadTemplate()
        }
        .alert("Office checklist could not be updated", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @MainActor
    private func loadTemplate() async {
        guard let selectedOfficeID else {
            draftTasks = []
            savedTasks = []
            revision = 0
            notice = nil
            return
        }
        do {
            let template = try await workspace.loadOfficeTemplate(
                officeID: selectedOfficeID, workflow: workflow
            )
            guard template.officeID == self.selectedOfficeID,
                  template.workflow == self.workflow else { return }
            draftTasks = template.tasks.map(DraftTask.init)
            savedTasks = template.tasks
            revision = template.version
            notice = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createOffice() {
        guard !isDirty else {
            errorMessage = "Save or discard your checklist edits before adding another office."
            return
        }
        isWorking = true
        let name = newOfficeName
        Task {
            defer { isWorking = false }
            do {
                let office = try await workspace.createOffice(named: name)
                newOfficeName = ""
                selectedOfficeID = office.id
                notice = "Office created."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func saveTemplate(afterSave: Destination? = nil) {
        guard let selectedOfficeID, !isWorking else { return }
        isWorking = true
        let submitted = draftTasks.map(\.task)
        let submittedWorkflow = workflow
        Task {
            defer { isWorking = false }
            do {
                let latest = try await workspace.saveOfficeTemplate(
                    officeID: selectedOfficeID, workflow: submittedWorkflow,
                    expectedVersion: revision, tasks: submitted
                )
                if self.selectedOfficeID == selectedOfficeID &&
                   self.workflow == submittedWorkflow {
                    draftTasks = latest.tasks.map(DraftTask.init)
                    savedTasks = latest.tasks
                    revision = latest.version
                    notice = "Office checklist saved. Existing transactions are unchanged."
                    if let afterSave { applyNavigation(afterSave) }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    private func moveTask(_ id: UUID, by direction: Int) {
        guard let current = draftTasks.firstIndex(where: { $0.id == id }),
              draftTasks.indices.contains(current + direction) else { return }
        draftTasks.swapAt(current, current + direction)
    }

    private func requestNavigation(_ target: Destination) {
        guard !isWorking else { return }
        if isDirty {
            pendingDestination = target
            showUnsavedConfirmation = true
        } else {
            applyNavigation(target)
        }
    }

    private func applyNavigation(_ destination: Destination) {
        switch destination {
        case .close:
            dismiss()
        case .office(let id):
            selectedOfficeID = id
        case .workflow(let kind):
            workflow = kind
        }
    }

}
