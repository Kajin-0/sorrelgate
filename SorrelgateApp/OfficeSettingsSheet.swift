import SorrelgateCore
import SwiftUI
import UniformTypeIdentifiers

/// Office configuration is an explicit user operation, not a global rewrite of
/// historical transactions. Existing transactions retain their checklist rows.
struct OfficeSettingsSheet: View {
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
    @State private var tasks: [OfficeTaskSpec] = []
    @State private var revision = 0
    @State private var isWorking = false
    @State private var notice: String?
    @State private var errorMessage: String?

    private var templateKey: String {
        (selectedOfficeID?.uuidString ?? "none") + ":" + workflow.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Office Checklists").font(.title2.weight(.semibold))
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.cancelAction)
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
            Picker("Office", selection: $selectedOfficeID) {
                Text("Choose an office").tag(nil as UUID?)
                ForEach(workspace.offices) { office in
                    Text(office.name).tag(Optional(office.id))
                }
            }
            if selectedOfficeID != nil {
                Picker("Work type", selection: $workflow) {
                    ForEach(WorkflowKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                HStack {
                    Text("Task order, office requirement, and notes").font(.headline)
                    Spacer()
                    Text("Revision \(revision)").font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                List {
                    ForEach(tasks.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text("\(index + 1)").monospacedDigit()
                                    .foregroundStyle(.secondary).frame(width: 24)
                                TextField("Task description", text: $tasks[index].title)
                                    .accessibilityLabel("Task \(index + 1)")
                                Button {
                                    tasks.swapAt(index, index - 1)
                                } label: {
                                    Image(systemName: "arrow.up")
                                }
                                .disabled(index == 0)
                                .help("Move task up")
                                Button {
                                    tasks.swapAt(index, index + 1)
                                } label: {
                                    Image(systemName: "arrow.down")
                                }
                                .disabled(index >= tasks.count - 1)
                                .help("Move task down")
                                Button {
                                    tasks.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .disabled(tasks.count <= 1)
                                .help("Remove task")
                            }
                            HStack {
                                Picker("Office requirement", selection: $tasks[index].requirement) {
                                    ForEach(OfficeTaskRequirement.allCases, id: \.self) { level in
                                        Text(level.displayName).tag(level)
                                    }
                                }
                                .frame(width: 230)
                                TextField("Notes (optional)", text: $tasks[index].notes)
                                    .accessibilityLabel("Notes for task \(index + 1)")
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                }
                HStack {
                    Button("Add Task") { tasks.append(OfficeTaskSpec(title: "New task")) }
                        .disabled(tasks.count >= 100 || isWorking)
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
                        .disabled(isWorking || tasks.isEmpty)
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
                tasks = imported
                notice = "Imported \(imported.count) tasks into this draft. Save to create a new revision."
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
                tasks = imported
                notice = "Imported \(imported.count) Excel tasks into this draft. Save to create a new revision."
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
            tasks = []
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
            tasks = template.tasks
            revision = template.version
            notice = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createOffice() {
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

    private func saveTemplate() {
        guard let selectedOfficeID else { return }
        isWorking = true
        let submitted = tasks
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
                    tasks = latest.tasks
                    revision = latest.version
                    notice = "Saved revision \(latest.version). Existing transactions are unchanged."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
