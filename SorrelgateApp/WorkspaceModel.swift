import Foundation
import SorrelgateCore

@MainActor
final class WorkspaceModel: ObservableObject {
    @Published private(set) var transactions: [TransactionRecord] = []
    @Published var selectedTransactionID: UUID?
    @Published var selectedDocumentID: UUID?
    @Published private(set) var documents: [ImportedDocument] = []
    @Published private(set) var tasks: [ChecklistItem] = []
    @Published private(set) var offices: [OfficeProfile] = []
    @Published private(set) var checklistSource: ChecklistSnapshot?
    @Published var errorMessage: String?
    @Published var noticeMessage: String?
    @Published private(set) var isImporting = false
    @Published private(set) var isCreatingTransaction = false
    @Published private(set) var importCount = 0
    @Published private(set) var importTotal = 0
    @Published var previewURL: URL?

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
                errorMessage = warning
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
            lastLoadedTransactionID = nil
            documents = []
            tasks = []
            checklistSource = nil
            selectedDocumentID = nil
            previewURL = nil
            return
        }
        if lastLoadedTransactionID != id {
            lastLoadedTransactionID = id
            selectedDocumentID = nil
            previewURL = nil
            documents = []
            tasks = []
            checklistSource = nil
        }
        Task {
            do {
                let loadedDocuments = try await workspace.documents(for: id)
                let loadedTasks = try await workspace.checklist(for: id)
                let snapshot = try await workspace.checklistSnapshot(for: id)
                guard selectedTransactionID == id else { return }
                documents = loadedDocuments
                tasks = loadedTasks
                checklistSource = snapshot
                if let selectedDocumentID,
                   let selected = loadedDocuments.first(where: { $0.id == selectedDocumentID }) {
                    previewURL = await workspace.storedPDFURL(for: selected)
                } else {
                    selectedDocumentID = nil
                    previewURL = nil
                }
            } catch {
                if selectedTransactionID == id {
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
                    if case .duplicate = result { duplicates += 1 }
                } catch {
                    if !(error is CancellationError) {
                        failures.append("\(url.lastPathComponent): \(error.localizedDescription)")
                    }
                }
                importCount += 1
            }
            if selectedTransactionID == transactionID {
                loadSelected()
            }
            if !failures.isEmpty {
                errorMessage = failures.prefix(4).joined(separator: "\n")
            } else if Task.isCancelled {
                noticeMessage = "Import cancelled. Completed documents were retained."
            } else {
                noticeMessage = "Processed \(importCount) PDFs" +
                    (duplicates > 0 ? " (\(duplicates) already imported)." : ".")
            }
        }
    }

    func cancelImport() {
        importTask?.cancel()
    }

    func selectDocument(_ document: ImportedDocument?) {
        guard let document, let workspace = documentWorkspace else {
            previewURL = nil
            return
        }
        selectedDocumentID = document.id
        Task {
            let url = await workspace.storedPDFURL(for: document)
            if selectedDocumentID == document.id {
                previewURL = url
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
                    noticeMessage = "Restored the original office checklist selected at creation."
                    return
                }
                let count = try await workspace.seedStarterChecklist(
                    for: transaction.id, workflow: transaction.workflow
                )
                if selectedTransactionID == transaction.id { loadSelected() }
                noticeMessage = count > 0
                    ? "Loaded \(count) starter tasks. Review for your office."
                    : "Your existing tasks were preserved."
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
                noticeMessage = "Saved transaction package to \(result.path)"
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
