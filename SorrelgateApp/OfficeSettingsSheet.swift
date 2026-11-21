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
    @State private var xlsxWorkbook: XLSXChecklistWorkbook?
    @State private var csvTable: CSVChecklistTable?
    @State private var selectedOfficeID: UUID?
    @State private var workflow: WorkflowKind = .acceptedOffer
    @State private var titles: [String] = []
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
                    Text("Task order and wording").font(.headline)
                    Spacer()
                    Text("Revision \(revision)").font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                List {
                    ForEach(titles.indices, id: \.self) { index in
                        HStack(spacing: 8) {
                            Text("\(index + 1)").monospacedDigit()
                                .foregroundStyle(.secondary).frame(width: 24)
                            TextField("Task description", text: $titles[index])
                                .accessibilityLabel("Task \(index + 1)")
                            Button {
                                titles.swapAt(index, index - 1)
                            } label: {
                                Image(systemName: "arrow.up")
                            }
                            .disabled(index == 0)
                            .help("Move task up")
                            Button {
                                titles.swapAt(index, index + 1)
                            } label: {
                                Image(systemName: "arrow.down")
                            }
                            .disabled(index >= titles.count - 1)
                            .help("Move task down")
                            Button {
                                titles.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .disabled(titles.count <= 1)
                            .help("Remove task")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                HStack {
                    Button("Add Task") { titles.append("New task") }
                        .disabled(titles.count >= 100 || isWorking)
                    Button("Import CSV") { isImportingCSV = true }
                        .disabled(isWorking)
                    Button("Import Excel") { isImportingXLSX = true }
                        .disabled(isWorking)
                    Spacer()
                    if let notice {
                        Text(notice).font(.caption).foregroundStyle(.secondary)
                    }
                    Button("Save Office Checklist") { saveTemplate() }
                        .buttonStyle(.borderedProminent)
                        .disabled(isWorking || titles.isEmpty)
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
                titles = imported
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
                    xlsxWorkbook = try XLSXChecklistImporter.parse(Data(contentsOf: url))
                } catch {
                    errorMessage = error.localizedDescription
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .sheet(item: $xlsxWorkbook) { workbook in
            XLSXSheetPickerSheet(workbook: workbook) { imported in
                titles = imported
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
            titles = []
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
            titles = template.titles
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
        let submitted = titles
        let submittedWorkflow = workflow
        Task {
            defer { isWorking = false }
            do {
                let latest = try await workspace.saveOfficeTemplate(
                    officeID: selectedOfficeID, workflow: submittedWorkflow,
                    expectedVersion: revision, titles: submitted
                )
                if self.selectedOfficeID == selectedOfficeID &&
                   self.workflow == submittedWorkflow {
                    titles = latest.titles
                    revision = latest.version
                    notice = "Saved revision \(latest.version). Existing transactions are unchanged."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
