import SwiftUI
import SorrelgateCore

struct MainView: View {
    @StateObject private var workspace = WorkspaceModel()
    @State private var isPresentingNewTransaction = false

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
            .navigationSplitViewColumnWidth(min: 235, ideal: 300)
            .toolbar {
                ToolbarItem {
                    Button {
                        isPresentingNewTransaction = true
                    } label: {
                        Label("New Transaction", systemImage: "plus")
                    }
                    .help("Create a transaction")
                }
            }
        } detail: {
            if let selected = workspace.transactions.first(
                where: { $0.id == workspace.selectedTransactionID }
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(selected.propertyAddress)
                        .font(.largeTitle.weight(.semibold))
                        .textSelection(.enabled)
                    Label(selected.workflow.displayName, systemImage: "checklist")
                        .foregroundStyle(.secondary)
                    Divider()
                    ContentUnavailableView(
                        "Ready for Documents",
                        systemImage: "doc.on.doc",
                        description: Text(
                            "The transaction has been saved on this Mac. Document import and checklists are the next milestone."
                        )
                    )
                    Spacer()
                }
                .padding(28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ContentUnavailableView {
                    Label("Start a Transaction", systemImage: "house")
                } description: {
                    Text("Create your first transaction to start organizing the work.")
                } actions: {
                    Button("New Transaction") {
                        isPresentingNewTransaction = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $isPresentingNewTransaction) {
            NewTransactionSheet { address, workflow in
                if workspace.create(address: address, workflow: workflow) {
                    isPresentingNewTransaction = false
                }
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
}

private struct NewTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var workflow: WorkflowKind = .acceptedOffer

    let onCreate: (String, WorkflowKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New Transaction")
                .font(.title2.weight(.semibold))
            TextField("Property address", text: $address)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Property address")
            Picker("Work type", selection: $workflow) {
                ForEach(WorkflowKind.allCases, id: \.self) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            Spacer(minLength: 8)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create Transaction") { onCreate(address, workflow) }
                    .buttonStyle(.borderedProminent)
                    .disabled(address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 475, height: 245)
    }
}
