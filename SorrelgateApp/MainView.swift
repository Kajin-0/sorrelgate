import AppKit
import SorrelgateCore
import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @StateObject private var workspace = WorkspaceModel()
    @State private var isPresentingNewTransaction = false
    @State private var isPresentingPDFPicker = false
    @State private var isPresentingOffices = false
    @State private var newTaskTitle = ""
    @State private var editingTask: ChecklistItem?

    var body: some View {
        NavigationSplitView {
            List(selection: $workspace.selectedTransactionID) {
                Section("Transactions") {
                    ForEach(workspace.transactions) { transaction in
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(transaction.propertyAddress)
                                    .font(.body.weight(.medium))
                                    .lineLimit(1)
                                Text(transaction.workflow.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "house")
                        }
                        .tag(transaction.id)
                    }
                }
            }
            .navigationTitle("Sorrelgate")
            .navigationSplitViewColumnWidth(min: 235, ideal: 295)
            .toolbar {
                ToolbarItem {
                    Button {
                        isPresentingOffices = true
                    } label: {
                        Label("Offices", systemImage: "building.2")
                    }
                }
                ToolbarItem {
                    Button {
                        isPresentingNewTransaction = true
                    } label: {
                        Label("New Transaction", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let transaction = workspace.transactions.first(
                where: { $0.id == workspace.selectedTransactionID }
            ) {
                transactionDetail(transaction)
            } else {
                ContentUnavailableView {
                    Label("Start a Transaction", systemImage: "house")
                } description: {
                    Text("Create your first transaction to start organizing the paperwork.")
                } actions: {
                    Button("New Transaction") { isPresentingNewTransaction = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .onChange(of: workspace.selectedTransactionID) { _, _ in
            workspace.loadSelected()
        }
        .sheet(item: $editingTask) { item in
            EditTaskSheet(
                task: item,
                onSave: { workspace.renameTask(item, to: $0) },
                onRemove: { workspace.removeTask(item) }
            )
        }
        .sheet(isPresented: $isPresentingNewTransaction) {
            NewTransactionSheet(offices: workspace.offices) { address, workflow, officeID in
                await workspace.create(address: address, workflow: workflow, officeID: officeID)
            }
        }
        .sheet(isPresented: $isPresentingOffices) {
            OfficeSettingsSheet(workspace: workspace)
        }
        .fileImporter(
            isPresented: $isPresentingPDFPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls): workspace.importFiles(urls)
            case .failure(let error): workspace.errorMessage = error.localizedDescription
            }
        }
        .alert(
            "Sorrelgate couldn't complete that action",
            isPresented: Binding(
                get: { workspace.errorMessage != nil },
                set: { if !$0 { workspace.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { workspace.errorMessage = nil }
        } message: {
            Text(workspace.errorMessage ?? "")
        }
    }

    private func transactionDetail(_ transaction: TransactionRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.propertyAddress)
                        .font(.title.weight(.semibold))
                        .textSelection(.enabled)
                    Text(transaction.workflow.displayName)
                        .foregroundStyle(.secondary)
                    if let source = workspace.checklistSource,
                       source.transactionID == transaction.id {
                        Text("Checklist: \(source.officeName) · revision \(source.templateVersion)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    isPresentingPDFPicker = true
                } label: {
                    Label("Import PDFs", systemImage: "plus")
                }
                .disabled(workspace.isImporting)
                Button {
                    chooseExportFolder()
                } label: {
                    Label("Export Package", systemImage: "square.and.arrow.up")
                }
                .disabled(workspace.isImporting)
            }
            if workspace.isImporting {
                HStack {
                    ProgressView(value: Double(workspace.importCount),
                                 total: Double(max(workspace.importTotal, 1)))
                        .frame(maxWidth: 260)
                    Text("\(workspace.importCount) / \(workspace.importTotal)")
                        .font(.caption.monospacedDigit())
                    Button("Cancel Import") { workspace.cancelImport() }
                }
            }
            if let notice = workspace.noticeMessage {
                Label(notice, systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .textSelection(.enabled)
            }
            Divider()
            HSplitView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Documents (\(workspace.documents.count))")
                        .font(.headline)
                    if workspace.documents.isEmpty {
                        ContentUnavailableView(
                            "No PDFs Yet",
                            systemImage: "doc.on.doc",
                            description: Text("Import the documents you've received for this transaction.")
                        )
                    } else {
                        List(selection: $workspace.selectedDocumentID) {
                            ForEach(workspace.documents) { document in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(document.originalName).lineLimit(2)
                                    Text("\(document.pageCount) page(s) · Saved locally")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                .tag(document.id)
                            }
                        }
                        .onChange(of: workspace.selectedDocumentID) { _, id in
                            workspace.selectDocument(
                                workspace.documents.first { $0.id == id }
                            )
                        }
                    }
                    Divider()
                    HStack {
                        Text("Checklist").font(.headline)
                        Spacer()
                        if workspace.tasks.isEmpty {
                            Button("Load Starter Tasks") {
                                workspace.loadStarterChecklist(for: transaction)
                            }
                        } else {
                            Text("\(workspace.tasks.filter(\.isCompleted).count) of \(workspace.tasks.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        TextField("Add a task", text: $newTaskTitle)
                            .onSubmit { addTask() }
                        Button {
                            addTask()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityLabel("Add checklist task")
                    }
                    List {
                        ForEach(workspace.tasks) { item in
                            HStack {
                                Toggle(isOn: Binding(
                                    get: { item.isCompleted },
                                    set: { workspace.setTask(item, completed: $0) }
                                )) {
                                    Text(item.title)
                                }
                                Menu {
                                    Button("No linked document") {
                                        workspace.linkTask(item, to: nil)
                                    }
                                    ForEach(workspace.documents) { document in
                                        Button(document.originalName) {
                                            workspace.linkTask(item, to: document.id)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "link")
                                }
                                .help("Link a PDF to this task")
                                Button {
                                    editingTask = item
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                                .buttonStyle(.borderless)
                                .help("Rename or remove this task")
                            }
                            if let linkedID = item.linkedDocumentID,
                               let document = workspace.documents.first(where: { $0.id == linkedID }) {
                                Text("Linked: \(document.originalName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(minWidth: 310, idealWidth: 390)

                VStack(alignment: .leading) {
                    Text("Document Preview")
                        .font(.headline)
                    if let url = workspace.previewURL {
                        PDFPreview(fileURL: url)
                            .accessibilityLabel("Selected PDF document preview")
                    } else {
                        ContentUnavailableView(
                            "Select a Document",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Choose a PDF to inspect its original pages.")
                        )
                    }
                }
                .frame(minWidth: 320, maxWidth: .infinity)
            }
        }
        .padding(20)
        .frame(minWidth: 760, minHeight: 520)
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        workspace.addTask(title)
        newTaskTitle = ""
    }

    private func chooseExportFolder() {
        let picker = NSOpenPanel()
        picker.message = "Choose where to save a new Sorrelgate folder"
        picker.canChooseFiles = false
        picker.canChooseDirectories = true
        picker.canCreateDirectories = true
        picker.allowsMultipleSelection = false
        picker.begin { result in
            guard result == .OK, let url = picker.url else { return }
            Task { @MainActor in workspace.export(to: url) }
        }
    }
}

private struct NewTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var workflow: WorkflowKind = .acceptedOffer
    @State private var officeID: UUID?
    @State private var isCreating = false
    let offices: [OfficeProfile]
    let onCreate: (String, WorkflowKind, UUID?) async -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New Transaction").font(.title2.weight(.semibold))
            TextField("Property address", text: $address)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Property address")
            Picker("Work type", selection: $workflow) {
                ForEach(WorkflowKind.allCases, id: \.self) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            Picker("Office checklist", selection: $officeID) {
                Text("Built-in starter").tag(nil as UUID?)
                ForEach(offices) { office in
                    Text(office.name).tag(Optional(office.id))
                }
            }
            Text("Selected office tasks are copied into this transaction.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .disabled(isCreating)
                    .keyboardShortcut(.cancelAction)
                if isCreating {
                    ProgressView().controlSize(.small)
                        .accessibilityLabel("Saving transaction")
                }
                Button("Create Transaction") {
                    guard !isCreating else { return }
                    isCreating = true
                    Task {
                        defer { isCreating = false }
                        if await onCreate(address, workflow, officeID) {
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    isCreating ||
                    address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 475, height: 295)
    }
}
