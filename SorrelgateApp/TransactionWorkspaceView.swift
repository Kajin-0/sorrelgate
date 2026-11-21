import SorrelgateCore
import SwiftUI

/// A review console for a transaction, not a second copy of domain logic.
/// All writes and source authorization remain inside WorkspaceModel/Core.
struct TransactionWorkspaceView: View {
    let transaction: TransactionRecord
    @ObservedObject var workspace: WorkspaceModel
    let onImport: () -> Void
    let onExport: () -> Void
    let onEditTask: (ChecklistItem) -> Void
    let onLoadStarter: () -> Void

    private enum Section: String, CaseIterable {
        case review = "Review"
        case documents = "Documents"
        case checklist = "Checklist"
    }

    @State private var section: Section = .review
    @State private var taskTitle = ""

    private var needsAttention: [FieldProposal] {
        workspace.fieldProposals.filter {
            $0.status == .proposed || $0.status == .unknown
        }
    }

    private var previousDecisions: [FieldProposal] {
        workspace.fieldProposals.filter {
            $0.status == .confirmed || $0.status == .rejected
        }
    }

    private var completedTaskCount: Int {
        workspace.tasks.filter(\.isCompleted).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(transaction.propertyAddress)
                        .font(.title2.weight(.semibold))
                        .textSelection(.enabled)
                        .lineLimit(2)
                    Text(transaction.workflow.displayName)
                        .foregroundStyle(.secondary)
                    if let source = workspace.checklistSource,
                       source.transactionID == transaction.id {
                        Text("Checklist: \(source.officeName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 4)
                Button {
                    onImport()
                } label: {
                    Label("Add PDFs", systemImage: "plus")
                }
                .disabled(workspace.isImporting)
                Button {
                    onExport()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(workspace.isImporting)
                .help("Save copies of documents and a checklist to a chosen folder")
            }

            HStack(spacing: 12) {
                Text("\(workspace.documents.count) PDFs")
                if workspace.fieldProposals.isEmpty {
                    Text("No suggestions yet")
                } else {
                    Text("\(needsAttention.count) awaiting review")
                }
                Text("\(completedTaskCount) of \(workspace.tasks.count) tasks done")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .combine)

            if workspace.isImporting {
                HStack(spacing: 12) {
                    ProgressView(
                        value: Double(workspace.importCount),
                        total: Double(max(workspace.importTotal, 1))
                    )
                    Text("\(workspace.importCount) of \(workspace.importTotal) PDFs")
                        .font(.caption)
                    Button("Cancel") { workspace.cancelImport() }
                }
            }

            if let notice = workspace.noticeMessage {
                Label(notice, systemImage: workspace.noticeKind.symbol)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Picker("Workspace", selection: $section) {
                ForEach(Section.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityLabel("Transaction workspace section")

            if workspace.isLoadingSelection {
                ProgressView("Opening transaction…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                sectionContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding(20)
        .frame(minWidth: 525, minHeight: 475)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .review:
            reviewSection
        case .documents:
            documentSection
        case .checklist:
            checklistSection
        }
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Details to check").font(.headline)
                Spacer()
                if !workspace.documents.isEmpty {
                    Button {
                        workspace.findKeyFactsInTransaction()
                    } label: {
                        Label("Find details in PDFs", systemImage: "doc.text.magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(workspace.isFindingProposals || workspace.isImporting)
                    .accessibilityHint("Find proposed dates and prices in all imported PDFs")
                }
            }
            Text("Suggested dates and prices are not confirmed. Open the original page before deciding.")
                .foregroundStyle(.secondary)
                .font(.callout)

            if workspace.isFindingProposals {
                ProgressView("Checking imported PDFs…")
                    .padding(.vertical, 8)
            }

            if workspace.documents.isEmpty {
                ContentUnavailableView {
                    Label("Start with your paperwork", systemImage: "doc.on.doc")
                } description: {
                    Text("Add PDFs to this transaction, then check any suggested details.")
                } actions: {
                    Button("Add PDFs", action: onImport)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        if needsAttention.isEmpty {
                            ContentUnavailableView {
                                Label("No details waiting for review", systemImage: "checklist")
                            } description: {
                                Text("Choose Find details in PDFs to look for labeled dates and prices. This does not check whether paperwork is complete.")
                            }
                        } else {
                            Text("\(needsAttention.count) to review")
                                .font(.subheadline.weight(.semibold))
                            ForEach(needsAttention) { proposal in
                                proposalCard(proposal)
                            }
                        }
                        if !previousDecisions.isEmpty {
                            DisclosureGroup("Previous decisions (\(previousDecisions.count))") {
                                LazyVStack(alignment: .leading, spacing: 12) {
                                    ForEach(previousDecisions) { proposal in
                                        proposalCard(proposal)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func proposalCard(_ proposal: FieldProposal) -> some View {
        let documentName = workspace.documents.first {
            $0.id == proposal.documentID
        }?.originalName ?? "Original PDF"
        let hasCompetingValue = proposal.status != .rejected &&
            workspace.fieldProposals.contains {
                $0.id != proposal.id &&
                $0.kind == proposal.kind &&
                $0.value != proposal.value &&
                $0.status != .rejected
            }

        return VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(proposal.kind.displayName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(statusText(proposal.status))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(proposal.value)
                .font(.title3.weight(.medium))
                .textSelection(.enabled)
            Text("\(documentName) · page \(proposal.pageIndex + 1)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            if hasCompetingValue {
                Label(
                    "Another document shows a different value. Compare both originals.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.callout)
                .foregroundStyle(.orange)
            }
            HStack(spacing: 10) {
                Button("View original") {
                    workspace.showProposalSource(proposal)
                }
                .accessibilityHint("Open the original PDF at page \(proposal.pageIndex + 1)")
                Spacer(minLength: 4)
                if proposal.status != .confirmed {
                    Button("Confirm") {
                        workspace.reviewProposal(proposal, as: .confirmed)
                    }
                    .buttonStyle(.borderedProminent)
                }
                if proposal.status != .unknown {
                    Button("Not sure") {
                        workspace.reviewProposal(proposal, as: .unknown)
                    }
                }
                if proposal.status != .rejected {
                    Button("Reject") {
                        workspace.reviewProposal(proposal, as: .rejected)
                    }
                }
            }
            .controlSize(.regular)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func statusText(_ status: FieldReviewStatus) -> String {
        switch status {
        case .proposed: "Not reviewed"
        case .unknown: "Not sure yet"
        case .confirmed: "Confirmed by you"
        case .rejected: "Rejected by you"
        }
    }

    private var documentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your PDFs").font(.headline)
            if workspace.documents.isEmpty {
                ContentUnavailableView(
                    "No PDFs added",
                    systemImage: "doc.on.doc",
                    description: Text("Use Add PDFs above to import files.")
                )
            } else {
                List(selection: $workspace.selectedDocumentID) {
                    ForEach(workspace.documents) { document in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(document.originalName)
                                .lineLimit(2)
                            Text("\(document.pageCount) \(document.pageCount == 1 ? "page" : "pages")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(document.id)
                    }
                }
                .frame(minHeight: 110, idealHeight: 160, maxHeight: 220)
                .onChange(of: workspace.selectedDocumentID) { _, id in
                    workspace.selectDocument(
                        workspace.documents.first(where: { $0.id == id })
                    )
                }
                if let url = workspace.previewURL {
                    PDFPreview(
                        fileURL: url,
                        pageIndex: workspace.previewPageIndex,
                        navigationToken: workspace.previewNavigationID
                    )
                    .accessibilityLabel("Original selected PDF")
                } else {
                    ContentUnavailableView(
                        "Choose a PDF",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Select a file above to read its original pages.")
                    )
                }
            }
        }
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Checklist").font(.headline)
                Spacer()
                if workspace.tasks.isEmpty {
                    Button("Use starter checklist", action: onLoadStarter)
                }
            }
            HStack {
                TextField("New task", text: $taskTitle)
                    .onSubmit(addTask)
                    .accessibilityLabel("Task description")
                Button("Add task", action: addTask)
                    .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            List {
                ForEach(workspace.tasks) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 12) {
                            Toggle(isOn: Binding(
                                get: { item.isCompleted },
                                set: { workspace.setTask(item, completed: $0) }
                            )) {
                                Text(item.title)
                            }
                            .toggleStyle(.checkbox)
                            Spacer(minLength: 0)
                            Menu {
                                Button("Edit task") {
                                    onEditTask(item)
                                }
                                if !workspace.documents.isEmpty {
                                    Menu("Link a PDF") {
                                        ForEach(workspace.documents) { document in
                                            Button(document.originalName) {
                                                workspace.linkTask(item, to: document.id)
                                            }
                                        }
                                    }
                                }
                                if item.linkedDocumentID != nil {
                                    Button("Remove PDF link") {
                                        workspace.linkTask(item, to: nil)
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                            .help("Task options")
                        }
                        if let linkedID = item.linkedDocumentID,
                           let document = workspace.documents.first(where: { $0.id == linkedID }) {
                            Text("PDF: \(document.originalName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .overlay {
                if workspace.tasks.isEmpty {
                    ContentUnavailableView(
                        "No tasks yet",
                        systemImage: "checklist",
                        description: Text("Add a task or load the starter checklist.")
                    )
                }
            }
        }
    }

    private func addTask() {
        let value = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        workspace.addTask(value)
        taskTitle = ""
    }
}
