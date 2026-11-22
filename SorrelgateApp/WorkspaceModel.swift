import Foundation
import SorrelgateCore

/// A source-page sheet is opened only after the domain layer has verified
/// transaction ownership, original SHA-256, and page bounds.
struct SourceDocumentPreview: Identifiable {
    let id = UUID()
    let url: URL
    let pageIndex: Int
    let documentName: String
}

@MainActor
final class WorkspaceModel: ObservableObject {
    @Published private(set) var transactions: [TransactionRecord] = []
    @Published var selectedTransactionID: UUID?
    @Published var selectedDocumentID: UUID?
    @Published private(set) var documents: [ImportedDocument] = []
    @Published private(set) var fieldProposals: [FieldProposal] = []
    @Published private(set) var tasks: [ChecklistItem] = []
    @Published private(set) var offices: [OfficeProfile] = []
    @Published private(set) var checklistSource: ChecklistSnapshot?
    @Published var errorMessage: String?
    @Published var noticeMessage: String?
    enum NoticeKind {
        case info, success, warning

        var symbol: String {
            switch self {
            case .info: "info.circle"
            case .success: "checkmark.circle"
            case .warning: "exclamationmark.triangle"
            }
        }
    }
    @Published private(set) var noticeKind: NoticeKind = .info
    @Published private(set) var isLoadingSelection = false
    @Published private(set) var isImporting = false
    @Published private(set) var isCreatingTransaction = false
    @Published private(set) var isFindingProposals = false
    @Published private(set) var importCount = 0
    @Published private(set) var importTotal = 0
    @Published var previewURL: URL?
    @Published var sourcePreview: SourceDocumentPreview?
    @Published private(set) var previewPageIndex = 0
    @Published private(set) var previewNavigationID = UUID()

    private var service: SorrelgateService?
    private var documentWorkspace: DocumentWorkspace?
    private var initializationCoordinator: TransactionInitializationCoordinator?
    private var importTask: Task<Void, Never>?
    private var lastLoadedTransactionID: UUID?

    init() {
        do {
            let directory = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            )[0].appendingPathComponent("Sorrelgate", isDirectory: true)
            let transactionService = SorrelgateService(
                store: try SQLiteTransactionStore(
                    fileURL: directory.appendingPathComponent("transactions.sqlite")
                )
            )
            let documents = try DocumentWorkspace(
                databaseURL: directory.appendingPathComponent("documents.sqlite"),
                documentsRoot: directory.appendingPathComponent("originals", isDirectory: true)
            )
            service = transactionService
            documentWorkspace = documents
            initializationCoordinator = TransactionInitializationCoordinator(
                service: transactionService, workspace: documents
            )
            refresh()
            loadSelected()
            Task {
                await reloadOffices()
                await recoverPendingChecklists()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() {
        guard let service else { return }
        do {
            guard case .transactions(let values) = try service.execute(.listTransactions)
            else { return }
            transactions = values
            if selectedTransactionID == nil,
               let storedID = UserDefaults.standard.string(forKey: "SorrelgateSelectedTransactionID"),
               let requested = UUID(uuidString: storedID),
               values.contains(where: { $0.id == requested }) {
                selectedTransactionID = requested
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reloadOffices() async {
        guard let documentWorkspace else { return }
        do {
            offices = try await documentWorkspace.offices()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createOffice(named name: String) async throws -> OfficeProfile {
        guard let documentWorkspace else {
            throw DocumentProcessingError.database("Workspace unavailable")
        }
        let office = try await documentWorkspace.createOffice(named: name)
        offices = try await documentWorkspace.offices()
        return office
    }

    func loadOfficeTemplate(
        officeID: UUID, workflow: WorkflowKind
    ) async throws -> OfficeChecklistTemplate {
        guard let documentWorkspace else {
            throw DocumentProcessingError.database("Workspace unavailable")
        }
        return try await documentWorkspace.officeTemplate(
            officeID: officeID, workflow: workflow
        )
    }

    func saveOfficeTemplate(
        officeID: UUID, workflow: WorkflowKind,
        expectedVersion: Int, tasks: [OfficeTaskSpec]
    ) async throws -> OfficeChecklistTemplate {
        guard let documentWorkspace else {
            throw DocumentProcessingError.database("Workspace unavailable")
        }
        return try await documentWorkspace.saveOfficeTemplate(
            officeID: officeID, workflow: workflow,
            expectedVersion: expectedVersion, tasks: tasks
        )
    }

    func create(
        address: String, workflow: WorkflowKind, officeID: UUID? = nil
    ) async -> Bool {
        guard !isCreatingTransaction, let initializationCoordinator else {
            errorMessage = "The transaction workspace is unavailable or already creating."
            return false
        }
        isCreatingTransaction = true
        defer { isCreatingTransaction = false }
        do {
            let outcome = try await initializationCoordinator.create(
                propertyAddress: address, workflow: workflow, officeID: officeID
            )
            refresh()
            selectedTransactionID = outcome.record.id
            loadSelected()
            if let warning = outcome.warning {
                noticeMessage = warning
                noticeKind = .warning
            } else {
                noticeMessage = "Transaction created."
                noticeKind = .success
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func recoverPendingChecklists() async {
        guard let initializationCoordinator else { return }
        do {
            let result = try await initializationCoordinator.recoverPending()
            if !result.completedTransactionIDs.isEmpty {
                if let selectedTransactionID,
                   result.completedTransactionIDs.contains(selectedTransactionID) {
                    loadSelected()
                }
                noticeMessage = "Recovered \(result.completedTransactionIDs.count) transaction checklist(s) after an interrupted save."
                noticeKind = .info
            }
            if !result.failures.isEmpty {
                errorMessage = "Checklist recovery could not finish for \(result.failures.count) transaction(s). Existing tasks were preserved; recovery will be retried."
            }
        } catch {
            errorMessage = "Checklist recovery could not be checked: " +
                error.localizedDescription
        }
    }

    func loadSelected() {
        guard let workspace = documentWorkspace, let id = selectedTransactionID else {
            sourcePreview = nil
            lastLoadedTransactionID = nil
            isLoadingSelection = false
            documents = []
            fieldProposals = []
            tasks = []
            checklistSource = nil
            selectedDocumentID = nil
            previewURL = nil
            previewPageIndex = 0
            return
        }
        if lastLoadedTransactionID != id {
            sourcePreview = nil
            lastLoadedTransactionID = id
            // A status from client A must not appear on client B's paperwork.
            noticeMessage = nil
            selectedDocumentID = nil
            previewURL = nil
            previewPageIndex = 0
            documents = []
            fieldProposals = []
            tasks = []
            checklistSource = nil
        }
        isLoadingSelection = true
        Task {
            do {
                let loadedDocuments = try await workspace.documents(for: id)
                let loadedTasks = try await workspace.checklist(for: id)
                let loadedProposals = try await workspace.fieldProposals(for: id)
                let snapshot = try await workspace.checklistSnapshot(for: id)
                guard selectedTransactionID == id else { return }
                documents = loadedDocuments
                isLoadingSelection = false
                tasks = loadedTasks
                fieldProposals = loadedProposals
                checklistSource = snapshot
                if let selectedDocumentID,
                   let selected = loadedDocuments.first(where: { $0.id == selectedDocumentID }) {
                    previewURL = try await workspace.sourcePDFURL(
                        documentID: selected.id, in: id
                    )
                } else {
                    selectedDocumentID = nil
                    previewURL = nil
                    previewPageIndex = 0
                }
            } catch {
                if selectedTransactionID == id {
                    isLoadingSelection = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func importFiles(_ urls: [URL]) {
        guard let workspace = documentWorkspace,
              let transactionID = selectedTransactionID,
              !isImporting else { return }
        isImporting = true
        importCount = 0
        importTotal = urls.count
        noticeMessage = nil

        importTask = Task {
            var failures: [String] = []
            var duplicates = 0
            var imported = 0
            // Keep authorized Finder security-scoped URLs alive across imports.
            let accessed = urls.filter { $0.startAccessingSecurityScopedResource() }
            defer {
                accessed.forEach { $0.stopAccessingSecurityScopedResource() }
                isImporting = false
                importTask = nil
            }
            for url in urls {
                if Task.isCancelled { break }
                do {
                    let result = try await workspace.importPDF(url, into: transactionID)
                    switch result {
                    case .imported: imported += 1
                    case .duplicate: duplicates += 1
                    }
                } catch {
                    if !(error is CancellationError) {
                        failures.append(ImportBatchReport.failure(
                            filename: url.lastPathComponent, reason: error.localizedDescription
                        ))
                    }
                }
                importCount += 1
            }
            // A background import cannot surface a result over another client's
            // transaction after the user has switched the sidebar selection.
            guard selectedTransactionID == transactionID else { return }
            loadSelected()
            let report = ImportBatchReport(
                imported: imported,
                alreadyPresent: duplicates,
                failed: failures.count,
                cancelled: Task.isCancelled
            )
            noticeMessage = report.summary
            noticeKind = !failures.isEmpty ? .warning :
                (Task.isCancelled ? .info : .success)
            if !failures.isEmpty {
                errorMessage = report.summary + "\n\n" +
                    ImportBatchReport.conciseFailures(failures)
            }
        }
    }

    func cancelImport() {
        importTask?.cancel()
    }

    func selectDocument(_ document: ImportedDocument?) {
        guard let document, let workspace = documentWorkspace,
              let transactionID = selectedTransactionID else {
            selectedDocumentID = nil
            previewURL = nil
            previewPageIndex = 0
            return
        }
        if selectedDocumentID != document.id {
            previewPageIndex = 0
            previewNavigationID = UUID()
        }
        selectedDocumentID = document.id
        previewURL = nil
        Task {
            do {
                let url = try await workspace.sourcePDFURL(
                    documentID: document.id, in: transactionID
                )
                guard selectedTransactionID == transactionID,
                      selectedDocumentID == document.id else { return }
                previewURL = url
            } catch {
                guard selectedTransactionID == transactionID,
                      selectedDocumentID == document.id else { return }
                previewURL = nil
                errorMessage = error.localizedDescription
            }
        }
    }

    /// One bounded, transaction-scoped call scans the already-imported PDFs.
    /// Every result is still proposed until the human reviews its source.
    func findKeyFactsInTransaction() {
        guard let workspace = documentWorkspace,
              let transactionID = selectedTransactionID,
              !isFindingProposals && !isImporting && !isLoadingSelection else { return }
        isFindingProposals = true
        noticeMessage = nil
        Task {
            defer { isFindingProposals = false }
            do {
                let matches = try await workspace.proposeKeyFacts(in: transactionID)
                guard selectedTransactionID == transactionID else { return }
                loadSelected()
                noticeMessage = matches.isEmpty
                    ? "No labeled dates or prices found. Check the documents yourself."
                    : "\(matches.count) details suggested. Check each original before confirming."
                noticeKind = .info
            } catch {
                if selectedTransactionID == transactionID {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func showProposalSource(_ proposal: FieldProposal) {
        guard let workspace = documentWorkspace,
              selectedTransactionID == proposal.transactionID else { return }
        Task {
            do {
                let url = try await workspace.sourcePDFURL(
                    for: proposal.id, in: proposal.transactionID
                )
                guard selectedTransactionID == proposal.transactionID else { return }
                selectedDocumentID = proposal.documentID
                previewPageIndex = proposal.pageIndex
                previewNavigationID = UUID()
                previewURL = url
                sourcePreview = SourceDocumentPreview(
                    url: url,
                    pageIndex: proposal.pageIndex,
                    documentName: documents.first(where: { $0.id == proposal.documentID })?.originalName ?? "Original PDF"
                )
            } catch {
                if selectedTransactionID == proposal.transactionID {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func reviewProposal(_ proposal: FieldProposal, as status: FieldReviewStatus) {
        guard let workspace = documentWorkspace,
              selectedTransactionID == proposal.transactionID else { return }
        Task {
            do {
                try await workspace.reviewFieldProposal(
                    proposal.id, in: proposal.transactionID, as: status
                )
                if selectedTransactionID == proposal.transactionID {
                    loadSelected()
                }
            } catch {
                if selectedTransactionID == proposal.transactionID {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func addTask(_ text: String) {
        guard let workspace = documentWorkspace, let id = selectedTransactionID else { return }
        Task {
            do {
                _ = try await workspace.addTask(text, for: id)
                loadSelected()
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func loadStarterChecklist(for transaction: TransactionRecord) {
        guard let workspace = documentWorkspace else { return }
        Task {
            do {
                // A saved office-specific creation intent takes precedence over
                // manual built-in tasks, even after a crash or fast UI navigation.
                if let initializationCoordinator,
                   try await initializationCoordinator.completePendingChecklist(
                       for: transaction.id
                   ) {
                    if selectedTransactionID == transaction.id { loadSelected() }
                    if selectedTransactionID == transaction.id {
                        noticeMessage = "Restored the original office checklist selected at creation."
                        noticeKind = .info
                    }
                    return
                }
                let count = try await workspace.seedStarterChecklist(
                    for: transaction.id, workflow: transaction.workflow
                )
                if selectedTransactionID == transaction.id { loadSelected() }
                if selectedTransactionID == transaction.id {
                    noticeMessage = count > 0
                        ? "Loaded \(count) starter tasks. Review for your office."
                        : "Your existing tasks were preserved."
                    noticeKind = .info
                }
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func renameTask(_ item: ChecklistItem, to title: String) {
        guard let workspace = documentWorkspace else { return }
        Task {
            do {
                try await workspace.renameTask(item.id, in: item.transactionID, to: title)
                if selectedTransactionID == item.transactionID { loadSelected() }
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func removeTask(_ item: ChecklistItem) {
        guard let workspace = documentWorkspace else { return }
        Task {
            do {
                try await workspace.removeTask(item.id, in: item.transactionID)
                if selectedTransactionID == item.transactionID { loadSelected() }
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func setTask(_ item: ChecklistItem, completed: Bool) {
        guard let workspace = documentWorkspace else { return }
        Task {
            do {
                try await workspace.updateTask(item.id, in: item.transactionID, completed: completed)
                loadSelected()
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func linkTask(_ item: ChecklistItem, to documentID: UUID?) {
        guard let workspace = documentWorkspace else { return }
        Task {
            do {
                try await workspace.linkDocument(
                    documentID, to: item.id, in: item.transactionID
                )
                loadSelected()
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func export(to folder: URL) {
        guard let workspace = documentWorkspace,
              let id = selectedTransactionID,
              let transaction = transactions.first(where: { $0.id == id }) else { return }
        Task {
            do {
                let result = try await workspace.export(
                    transactionID: id,
                    propertyAddress: transaction.propertyAddress,
                    to: folder
                )
                if selectedTransactionID == id {
                    noticeMessage = "Saved transaction package to \(result.path)"
                    noticeKind = .success
                }
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
