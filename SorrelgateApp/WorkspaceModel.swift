import Foundation
import SorrelgateCore

@MainActor
final class WorkspaceModel: ObservableObject {
    @Published private(set) var transactions: [TransactionRecord] = []
    @Published var selectedTransactionID: UUID?
    @Published var selectedDocumentID: UUID?
    @Published private(set) var documents: [ImportedDocument] = []
    @Published private(set) var tasks: [ChecklistItem] = []
    @Published var errorMessage: String?
    @Published var noticeMessage: String?
    @Published private(set) var isImporting = false
    @Published private(set) var importCount = 0
    @Published private(set) var importTotal = 0
    @Published var previewURL: URL?

    private var service: SorrelgateService?
    private var documentWorkspace: DocumentWorkspace?
    private var importTask: Task<Void, Never>?
    private var lastLoadedTransactionID: UUID?

    init() {
        do {
            let directory = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            )[0].appendingPathComponent("Sorrelgate", isDirectory: true)
            service = SorrelgateService(
                store: try SQLiteTransactionStore(
                    fileURL: directory.appendingPathComponent("transactions.sqlite")
                )
            )
            documentWorkspace = try DocumentWorkspace(
                databaseURL: directory.appendingPathComponent("documents.sqlite"),
                documentsRoot: directory.appendingPathComponent("originals", isDirectory: true)
            )
            refresh()
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

    func create(address: String, workflow: WorkflowKind) -> Bool {
        guard let service else {
            errorMessage = "The local database is unavailable."
            return false
        }
        do {
            guard case .created(let transaction) = try service.execute(
                .createTransaction(propertyAddress: address, workflow: workflow)
            ) else { return false }
            refresh()
            selectedTransactionID = transaction.id
            loadSelected()
            if let documentWorkspace {
                Task {
                    do {
                        _ = try await documentWorkspace.seedStarterChecklist(
                            for: transaction.id, workflow: workflow
                        )
                        if selectedTransactionID == transaction.id { loadSelected() }
                    } catch {
                        errorMessage = "Transaction saved, but starter tasks failed to load: " +
                            error.localizedDescription
                    }
                }
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func loadSelected() {
        guard let workspace = documentWorkspace, let id = selectedTransactionID else {
            lastLoadedTransactionID = nil
            documents = []
            tasks = []
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
        }
        Task {
            do {
                let loadedDocuments = try await workspace.documents(for: id)
                let loadedTasks = try await workspace.checklist(for: id)
                guard selectedTransactionID == id else { return }
                documents = loadedDocuments
                tasks = loadedTasks
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
