import AppKit
import SorrelgateCore
import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @StateObject private var workspace = WorkspaceModel()
    @State private var isPresentingNewTransaction = false
    @State private var isPresentingPDFPicker = false
    @State private var isPresentingOffices = false
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
                        Label("Office checklists", systemImage: "building.2")
                    }
                }
                ToolbarItem {
                    Button {
                        isPresentingNewTransaction = true
                    } label: {
                        Label("New Transaction", systemImage: "plus")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
        } detail: {
            if let transaction = workspace.transactions.first(
                where: { $0.id == workspace.selectedTransactionID }
            ) {
                transactionDetail(transaction)
            } else if workspace.transactions.isEmpty {
                SorrelgateEmptyState(
                    title: "Start a Transaction",
                    icon: "house",
                    description: "Create your first transaction to start organizing the paperwork.",
                    actionTitle: "New Transaction",
                    onAction: { isPresentingNewTransaction = true }
                )
            } else {
                SorrelgateEmptyState(
                    title: "Select a Transaction",
                    icon: "house",
                    description: "Choose an existing transaction from the sidebar."
                )
            }
        }
        .onChange(of: workspace.selectedTransactionID) { id in
            if let id {
                UserDefaults.standard.set(
                    id.uuidString, forKey: "SorrelgateSelectedTransactionID"
                )
            } else {
                UserDefaults.standard.removeObject(forKey: "SorrelgateSelectedTransactionID")
            }
            workspace.loadSelected()
        }
        .sheet(item: $editingTask) { item in
            EditTaskSheet(
                task: item,
                onSave: { workspace.renameTask(item, to: $0) },
                onRemove: { workspace.removeTask(item) }
            )
        }
        .sheet(item: $workspace.sourcePreview) { source in
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Original document").font(.headline)
                        Text("\(source.documentName) · page \(source.pageIndex + 1)")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Button("Done") { workspace.sourcePreview = nil }
                        .keyboardShortcut(.cancelAction)
                }
                PDFPreview(
                    fileURL: source.url,
                    pageIndex: source.pageIndex,
                    navigationToken: source.id
                )
                .accessibilityLabel("Source PDF, page \(source.pageIndex + 1)")
                Text("Compare this page with the suggested value before deciding.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(minWidth: 670, minHeight: 540)
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
        TransactionWorkspaceView(
            transaction: transaction,
            workspace: workspace,
            onImport: { isPresentingPDFPicker = true },
            onExport: { chooseExportFolder() },
            onEditTask: { editingTask = $0 },
            onLoadStarter: { workspace.loadStarterChecklist(for: transaction) }
        )
        .id(transaction.id)
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
