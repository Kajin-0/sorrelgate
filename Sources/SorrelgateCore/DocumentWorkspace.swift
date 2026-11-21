import AppKit
import CryptoKit
import Foundation
import PDFKit
import SQLite3
import Vision

public enum DocumentProcessingError: Error, LocalizedError {
    case invalidPDF(String)
    case noPages
    case missingDocument
    case invalidChecklistTask
    case invalidTaskTitle
    case duplicateDestination
    case corruptedOriginal(String)
    case storage(String)
    case database(String)

    public var errorDescription: String? {
        switch self {
        case .invalidPDF(let name): "Could not open '\(name)' as a valid PDF."
        case .noPages: "The PDF has no readable pages."
        case .missingDocument: "That document could not be found."
        case .invalidChecklistTask: "That checklist item could not be found in this transaction."
        case .invalidTaskTitle: "Enter a task description (1–250 characters)."
        case .duplicateDestination: "The destination contains an unexpected file. Nothing was overwritten."
        case .corruptedOriginal(let name): "Stored document '\(name)' failed its integrity check."
        case .storage(let message): "Local document storage failed: \(message)"
        case .database(let message): "Document storage error: \(message)"
        }
    }
}

public enum ExtractedTextMethod: String, Codable, Sendable {
    case digital
    case vision
    case unavailable
}

public struct DocumentPageText: Equatable, Sendable {
    public let pageIndex: Int
    public let text: String
    public let method: ExtractedTextMethod
}

public struct ImportedDocument: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let transactionID: UUID
    public let originalName: String
    public let sha256: String
    public let pageCount: Int
    public let createdAt: Date

    public init(
        id: UUID, transactionID: UUID, originalName: String,
        sha256: String, pageCount: Int, createdAt: Date
    ) {
        self.id = id
        self.transactionID = transactionID
        self.originalName = originalName
        self.sha256 = sha256
        self.pageCount = pageCount
        self.createdAt = createdAt
    }
}

public enum ImportDisposition: Sendable {
    case imported(ImportedDocument)
    case duplicate(ImportedDocument)
}

public struct ChecklistItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let transactionID: UUID
    public let title: String
    public let isCompleted: Bool
    public let linkedDocumentID: UUID?
    public let requirement: OfficeTaskRequirement
    public let notes: String

    public init(
        id: UUID, transactionID: UUID, title: String, isCompleted: Bool,
        linkedDocumentID: UUID?, requirement: OfficeTaskRequirement = .unspecified,
        notes: String = ""
    ) {
        self.id = id
        self.transactionID = transactionID
        self.title = title
        self.isCompleted = isCompleted
        self.linkedDocumentID = linkedDocumentID
        self.requirement = requirement
        self.notes = notes
    }
}

/// Separates document and task processing from the UI. The future LLM agent
/// must use this same permission-controlled domain API, not private SQL.
public actor DocumentWorkspace {
    private let store: DocumentSQLiteStore
    private let officeTemplates: OfficeTemplateStore
    private let documentsRoot: URL

    public init(databaseURL: URL, documentsRoot: URL) throws {
        try FileManager.default.createDirectory(
            at: documentsRoot, withIntermediateDirectories: true
        )
        self.documentsRoot = documentsRoot
        self.store = try DocumentSQLiteStore(fileURL: databaseURL)
        self.officeTemplates = try OfficeTemplateStore(databaseURL: databaseURL)
    }

    public func documents(for transactionID: UUID) throws -> [ImportedDocument] {
        try store.documents(transactionID: transactionID)
    }

    public func checklist(for transactionID: UUID) throws -> [ChecklistItem] {
        try store.checklist(transactionID: transactionID)
    }

    public func pageText(documentID: UUID) throws -> [DocumentPageText] {
        try store.pageText(documentID: documentID)
    }

    public func storedPDFURL(for document: ImportedDocument) -> URL {
        documentsRoot
            .appendingPathComponent(document.transactionID.uuidString, isDirectory: true)
            .appendingPathComponent(document.sha256 + ".pdf")
    }

    public func addTask(_ title: String, for transactionID: UUID) throws -> ChecklistItem {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean.count <= 250 else {
            throw DocumentProcessingError.invalidTaskTitle
        }
        let item = ChecklistItem(
            id: UUID(), transactionID: transactionID,
            title: clean, isCompleted: false, linkedDocumentID: nil
        )
        try store.addTask(item)
        return item
    }

    /// Creates immutable checklist rows and provenance as one SQLite transaction.
    /// Existing manual tasks and previously seeded transactions are never overwritten.
    @discardableResult
    public func seedStarterChecklist(
        for transactionID: UUID, workflow: WorkflowKind, officeID: UUID? = nil
    ) throws -> Int {
        try officeTemplates.seedTransaction(
            transactionID, workflow: workflow, officeID: officeID
        )
    }

    /// Freeze selected template and metadata before a transaction is recorded.
    public func prepareChecklistSeed(
        workflow: WorkflowKind, officeID: UUID? = nil
    ) throws -> ChecklistSeedPlan {
        try officeTemplates.prepareSeed(workflow: workflow, officeID: officeID)
    }

    /// Replay an immutable creation intent; no lookup of current office templates.
    @discardableResult
    public func applyPreparedChecklistSeed(
        _ plan: ChecklistSeedPlan, for transactionID: UUID
    ) throws -> Int {
        try officeTemplates.seedPreparedTransaction(transactionID, plan: plan)
    }

    public func offices() throws -> [OfficeProfile] {
        try officeTemplates.offices()
    }

    public func createOffice(named name: String) throws -> OfficeProfile {
        try officeTemplates.createOffice(named: name)
    }

    public func officeTemplate(
        officeID: UUID, workflow: WorkflowKind
    ) throws -> OfficeChecklistTemplate {
        try officeTemplates.template(officeID: officeID, workflow: workflow)
    }

    @discardableResult
    public func saveOfficeTemplate(
        officeID: UUID, workflow: WorkflowKind,
        expectedVersion: Int, titles: [String]
    ) throws -> OfficeChecklistTemplate {
        try officeTemplates.saveTemplate(
            officeID: officeID, workflow: workflow,
            expectedVersion: expectedVersion, titles: titles
        )
    }

    @discardableResult
    public func saveOfficeTemplate(
        officeID: UUID, workflow: WorkflowKind,
        expectedVersion: Int, tasks: [OfficeTaskSpec]
    ) throws -> OfficeChecklistTemplate {
        try officeTemplates.saveTemplate(
            officeID: officeID, workflow: workflow,
            expectedVersion: expectedVersion, tasks: tasks
        )
    }

    public func checklistSnapshot(for transactionID: UUID) throws -> ChecklistSnapshot? {
        try officeTemplates.snapshot(transactionID: transactionID)
    }

    public func renameTask(_ taskID: UUID, in transactionID: UUID, to title: String) throws {
        let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 250 else {
            throw DocumentProcessingError.invalidTaskTitle
        }
        try store.renameTask(taskID, transactionID: transactionID, title: value)
    }

    public func removeTask(_ taskID: UUID, in transactionID: UUID) throws {
        try store.removeTask(taskID, transactionID: transactionID)
    }

    public func updateTask(_ taskID: UUID, in transactionID: UUID, completed: Bool) throws {
        try store.updateTask(taskID, transactionID: transactionID, completed: completed)
    }

    public func linkDocument(
        _ documentID: UUID?, to taskID: UUID, in transactionID: UUID
    ) throws {
        try store.linkDocument(documentID, to: taskID, transactionID: transactionID)
    }

    /// Expects a Finder/fileImporter-approved local URL. The GUI acquires
    /// security-scoped file permission before invoking this operation.
    /// Sources are never renamed or modified.
    public func importPDF(_ sourceURL: URL, into transactionID: UUID) throws -> ImportDisposition {
        try Task<Never, Never>.checkCancellation()

        let directory = documentsRoot.appendingPathComponent(
            transactionID.uuidString, isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        let staged = directory.appendingPathComponent(
            ".incoming-" + UUID().uuidString + ".pdf"
        )
        defer { try? FileManager.default.removeItem(at: staged) }

        let sha = try Self.copyAndHash(source: sourceURL, to: staged)
        try Task<Never, Never>.checkCancellation()
        guard let pdf = PDFDocument(url: staged) else {
            throw DocumentProcessingError.invalidPDF(sourceURL.lastPathComponent)
        }
        guard pdf.pageCount > 0 else { throw DocumentProcessingError.noPages }
        try Task<Never, Never>.checkCancellation()

        if let existing = try store.findDocument(
            transactionID: transactionID, sha256: sha
        ) {
            // A DB duplicate is not proof that its original PDF still exists
            // or is intact. Never claim "already imported" for a lost or
            // corrupted stored source.
            guard let storedHash = try? Self.hashFile(at: storedPDFURL(for: existing)),
                  storedHash == sha else {
                throw DocumentProcessingError.corruptedOriginal(existing.originalName)
            }
            return .duplicate(existing)
        }

        var pages: [DocumentPageText] = []
        pages.reserveCapacity(pdf.pageCount)
        for index in 0..<pdf.pageCount {
            try Task<Never, Never>.checkCancellation()
            guard let page = pdf.page(at: index) else {
                pages.append(DocumentPageText(
                    pageIndex: index, text: "", method: .unavailable
                ))
                continue
            }
            let extracted = (page.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if extracted.count >= 15 {
                pages.append(DocumentPageText(
                    pageIndex: index, text: extracted, method: .digital
                ))
            } else {
                // Image-only pages: attempt on-device Vision OCR. OCR failure
                // leaves a reviewable page, not a falsely successful extraction.
                let recognized = Self.recognizeText(page: page)
                // Vision's synchronous request may have taken time; discard
                // uncommitted results if the owning import was cancelled.
                try Task<Never, Never>.checkCancellation()
                pages.append(DocumentPageText(
                    pageIndex: index,
                    text: recognized,
                    method: recognized.isEmpty ? .unavailable : .vision
                ))
            }
        }
        try Task<Never, Never>.checkCancellation()

        let destination = directory.appendingPathComponent(sha + ".pdf")
        var moved = false
        if FileManager.default.fileExists(atPath: destination.path) {
            let existingHash = try Self.hashFile(at: destination)
            guard existingHash == sha else {
                throw DocumentProcessingError.corruptedOriginal(sourceURL.lastPathComponent)
            }
        } else {
            try FileManager.default.moveItem(at: staged, to: destination)
            moved = true
        }

        let doc = ImportedDocument(
            id: UUID(), transactionID: transactionID,
            originalName: sourceURL.lastPathComponent,
            sha256: sha, pageCount: pdf.pageCount,
            createdAt: Date()
        )
        do {
            // Cancellation in the window after the file move must also roll
            // back the newly installed original, before SQLite is changed.
            try Task<Never, Never>.checkCancellation()
            try store.insertDocument(doc, pages: pages)
        } catch {
            if moved { try? FileManager.default.removeItem(at: destination) }
            throw error
        }
        return .imported(doc)
    }

    /// Creates a new destination folder; never overwrites or modifies any
    /// user-owned file. A JSON manifest and readable checklist accompany copies.
    public func export(
        transactionID: UUID, propertyAddress: String, to parentFolder: URL
    ) throws -> URL {
        let documents = try store.documents(transactionID: transactionID)
        let tasks = try store.checklist(transactionID: transactionID)
        let safeAddress = Self.safeFileName(propertyAddress)
        let folderName = "Sorrelgate-" + safeAddress + "-" +
            String(transactionID.uuidString.prefix(8))
        let destination = parentFolder.appendingPathComponent(
            folderName + "-" + UUID().uuidString.prefix(6), isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: destination, withIntermediateDirectories: false
        )
        do {
            var manifest: [[String: String]] = []
            for (offset, document) in documents.enumerated() {
                try Task<Never, Never>.checkCancellation()
                let from = storedPDFURL(for: document)
                guard try Self.hashFile(at: from) == document.sha256 else {
                    throw DocumentProcessingError.corruptedOriginal(document.originalName)
                }
                let filename = String(format: "%03d", offset + 1) + "-" +
                    Self.safeFileName(
                        (document.originalName as NSString).deletingPathExtension
                    ) + ".pdf"
                let output = destination.appendingPathComponent(filename)
                guard !FileManager.default.fileExists(atPath: output.path) else {
                    throw DocumentProcessingError.duplicateDestination
                }
                try FileManager.default.copyItem(at: from, to: output)
                guard try Self.hashFile(at: output) == document.sha256 else {
                    throw DocumentProcessingError.corruptedOriginal(document.originalName)
                }
                manifest.append([
                    "originalName": document.originalName,
                    "exportName": filename,
                    "sha256": document.sha256,
                    "documentID": document.id.uuidString,
                    "pageCount": String(document.pageCount)
                ])
            }
            let report = [
                "SORRELGATE TRANSACTION CHECKLIST",
                "Property: \(propertyAddress)",
                "Generated: \(ISO8601DateFormatter().string(from: Date()))",
                "Document count: \(documents.count)",
                "",
                "Items:"
            ] + tasks.map {
                let mark = $0.isCompleted ? "[x]" : "[ ]"
                let linked = $0.linkedDocumentID.flatMap { id in
                    documents.first { $0.id == id }?.originalName
                } ?? "No linked document"
                return "\(mark) \($0.title) — \(linked)"
            }
            try (report.joined(separator: "\n") + "\n")
                .write(to: destination.appendingPathComponent("Checklist.txt"),
                       atomically: true, encoding: .utf8)
            let data = try JSONSerialization.data(
                withJSONObject: [
                    "transactionID": transactionID.uuidString,
                    "propertyAddress": propertyAddress,
                    "documents": manifest
                ] as [String: Any],
                options: [.prettyPrinted, .sortedKeys]
            )
            try data.write(
                to: destination.appendingPathComponent("Manifest.json"),
                options: .atomic
            )
            return destination
        } catch {
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
    }

    private static func safeFileName(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(
            CharacterSet(charactersIn: " -_")
        )
        let value = name.unicodeScalars.map { allowed.contains($0) ? String($0) : "-" }
            .joined().trimmingCharacters(in: .whitespacesAndNewlines)
        return String((value.isEmpty ? "Untitled" : value).prefix(64))
    }

    private static func copyAndHash(source: URL, to destination: URL) throws -> String {
        let input = try FileHandle(forReadingFrom: source)
        defer { try? input.close() }
        guard FileManager.default.createFile(atPath: destination.path, contents: nil) else {
            throw DocumentProcessingError.storage(
                "Unable to create a temporary PDF copy. Check free disk space and folder permissions."
            )
        }
        let output = try FileHandle(forWritingTo: destination)
        defer { try? output.close() }
        var hash = SHA256()
        while let data = try input.read(upToCount: 256 * 1024), !data.isEmpty {
            try Task<Never, Never>.checkCancellation()
            try output.write(contentsOf: data)
            try Task<Never, Never>.checkCancellation()
            hash.update(data: data)
        }
        try output.synchronize()
        try Task<Never, Never>.checkCancellation()
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func hashFile(at url: URL) throws -> String {
        let input = try FileHandle(forReadingFrom: url)
        defer { try? input.close() }
        var hash = SHA256()
        while let data = try input.read(upToCount: 256 * 1024), !data.isEmpty {
            hash.update(data: data)
        }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func recognizeText(page: PDFPage) -> String {
        let image = page.thumbnail(of: CGSize(width: 1800, height: 1800), for: .mediaBox)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return "" }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        do {
            try VNImageRequestHandler(cgImage: cgImage).perform([request])
            return (request.results ?? []).compactMap {
                $0.topCandidates(1).first?.string
            }.joined(separator: "\n")
        } catch {
            return ""
        }
    }
}

/// SQLite state is confined to DocumentWorkspace's actor. No GUI or future
/// agent caller can execute arbitrary SQL.
private final class DocumentSQLiteStore {
    private var database: OpaquePointer?

    init(fileURL: URL) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let status = sqlite3_open_v2(
            fileURL.path, &database,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil
        )
        guard status == SQLITE_OK else {
            let message = database.map { String(cString: sqlite3_errmsg($0)) } ?? "Open failed."
            if let database { sqlite3_close(database) }
            database = nil
            throw DocumentProcessingError.database(message)
        }
        sqlite3_busy_timeout(database, 3000)
        try execute("""
            PRAGMA journal_mode=WAL;
            PRAGMA foreign_keys=ON;
            CREATE TABLE IF NOT EXISTS documents(
              id TEXT PRIMARY KEY NOT NULL,
              transaction_id TEXT NOT NULL,
              original_name TEXT NOT NULL,
              sha256 TEXT NOT NULL,
              page_count INTEGER NOT NULL,
              created_at REAL NOT NULL,
              UNIQUE(transaction_id, sha256)
            );
            CREATE INDEX IF NOT EXISTS idx_document_transaction ON documents(transaction_id);
            CREATE TABLE IF NOT EXISTS document_pages(
              document_id TEXT NOT NULL,
              page_index INTEGER NOT NULL,
              text TEXT NOT NULL,
              method TEXT NOT NULL,
              PRIMARY KEY(document_id, page_index),
              FOREIGN KEY(document_id) REFERENCES documents(id) ON DELETE CASCADE
            );
            CREATE TABLE IF NOT EXISTS checklist_tasks(
              id TEXT PRIMARY KEY NOT NULL,
              transaction_id TEXT NOT NULL,
              title TEXT NOT NULL,
              completed INTEGER NOT NULL DEFAULT 0,
              linked_document_id TEXT,
              requirement TEXT NOT NULL DEFAULT 'unspecified',
              notes TEXT NOT NULL DEFAULT '',
              FOREIGN KEY(linked_document_id) REFERENCES documents(id)
            );
            CREATE INDEX IF NOT EXISTS idx_task_transaction ON checklist_tasks(transaction_id);
        """)
        try addColumnIfNeeded(table: "checklist_tasks", name: "requirement",
                              definition: "TEXT NOT NULL DEFAULT 'unspecified'")
        try addColumnIfNeeded(table: "checklist_tasks", name: "notes",
                              definition: "TEXT NOT NULL DEFAULT ''")
    }

    deinit {
        if let database { sqlite3_close(database) }
    }

    func documents(transactionID: UUID) throws -> [ImportedDocument] {
        try withStatement("""
            SELECT id, transaction_id, original_name, sha256, page_count, created_at
            FROM documents WHERE transaction_id=? ORDER BY created_at ASC, id ASC;
            """) { statement in
                try bind(transactionID.uuidString, at: 1, to: statement)
                var values: [ImportedDocument] = []
                while true {
                    let result = sqlite3_step(statement)
                    if result == SQLITE_DONE { return values }
                    guard result == SQLITE_ROW else { throw error }
                    guard let id = UUID(uuidString: text(statement, index: 0)),
                          let parentID = UUID(uuidString: text(statement, index: 1))
                    else { throw DocumentProcessingError.database("Invalid document ID") }
                    values.append(ImportedDocument(
                        id: id, transactionID: parentID,
                        originalName: text(statement, index: 2),
                        sha256: text(statement, index: 3),
                        pageCount: Int(sqlite3_column_int(statement, 4)),
                        createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 5))
                    ))
                }
            }
    }

    func findDocument(transactionID: UUID, sha256: String) throws -> ImportedDocument? {
        try documents(transactionID: transactionID).first { $0.sha256 == sha256 }
    }

    func pageText(documentID: UUID) throws -> [DocumentPageText] {
        try withStatement("""
            SELECT page_index, text, method FROM document_pages
            WHERE document_id=? ORDER BY page_index;
            """) { statement in
                try bind(documentID.uuidString, at: 1, to: statement)
                var pages: [DocumentPageText] = []
                while true {
                    let result = sqlite3_step(statement)
                    if result == SQLITE_DONE { return pages }
                    guard result == SQLITE_ROW else { throw error }
                    pages.append(DocumentPageText(
                        pageIndex: Int(sqlite3_column_int(statement, 0)),
                        text: text(statement, index: 1),
                        method: ExtractedTextMethod(
                            rawValue: text(statement, index: 2)
                        ) ?? .unavailable
                    ))
                }
            }
    }

    func insertDocument(_ document: ImportedDocument, pages: [DocumentPageText]) throws {
        try execute("BEGIN IMMEDIATE TRANSACTION;")
        do {
            try withStatement("""
                INSERT INTO documents
                (id, transaction_id, original_name, sha256, page_count, created_at)
                VALUES (?, ?, ?, ?, ?, ?);
                """) { statement in
                    try bind(document.id.uuidString, at: 1, to: statement)
                    try bind(document.transactionID.uuidString, at: 2, to: statement)
                    try bind(document.originalName, at: 3, to: statement)
                    try bind(document.sha256, at: 4, to: statement)
                    sqlite3_bind_int(statement, 5, Int32(document.pageCount))
                    sqlite3_bind_double(statement, 6, document.createdAt.timeIntervalSince1970)
                    guard sqlite3_step(statement) == SQLITE_DONE else { throw error }
                }
            try withStatement("""
                INSERT INTO document_pages(document_id,page_index,text,method)
                VALUES (?,?,?,?);
                """) { statement in
                    for page in pages {
                        sqlite3_reset(statement)
                        sqlite3_clear_bindings(statement)
                        try bind(document.id.uuidString, at: 1, to: statement)
                        sqlite3_bind_int(statement, 2, Int32(page.pageIndex))
                        try bind(page.text, at: 3, to: statement)
                        try bind(page.method.rawValue, at: 4, to: statement)
                        guard sqlite3_step(statement) == SQLITE_DONE else { throw error }
                    }
                }
            try execute("COMMIT;")
        } catch {
            try? execute("ROLLBACK;")
            throw error
        }
    }

    func checklist(transactionID: UUID) throws -> [ChecklistItem] {
        try withStatement("""
            SELECT id, transaction_id, title, completed, linked_document_id,
                   requirement, notes
            FROM checklist_tasks WHERE transaction_id=? ORDER BY rowid;
            """) { statement in
                try bind(transactionID.uuidString, at: 1, to: statement)
                var items: [ChecklistItem] = []
                while true {
                    let result = sqlite3_step(statement)
                    if result == SQLITE_DONE { return items }
                    guard result == SQLITE_ROW else { throw error }
                    guard let id = UUID(uuidString: text(statement, index: 0)),
                          let parentID = UUID(uuidString: text(statement, index: 1))
                    else { throw DocumentProcessingError.database("Invalid checklist ID") }
                    let linked = sqlite3_column_type(statement, 4) == SQLITE_NULL
                        ? nil : UUID(uuidString: text(statement, index: 4))
                    guard let requirement = OfficeTaskRequirement(
                        rawValue: text(statement, index: 5)
                    ) else {
                        throw DocumentProcessingError.database("Invalid checklist requirement")
                    }
                    items.append(ChecklistItem(
                        id: id, transactionID: parentID,
                        title: text(statement, index: 2),
                        isCompleted: sqlite3_column_int(statement, 3) != 0,
                        linkedDocumentID: linked,
                        requirement: requirement,
                        notes: text(statement, index: 6)
                    ))
                }
            }
    }

    func addTask(_ task: ChecklistItem) throws {
        try withStatement("""
            INSERT INTO checklist_tasks (id, transaction_id, title)
            VALUES (?, ?, ?);
            """) { statement in
                try bind(task.id.uuidString, at: 1, to: statement)
                try bind(task.transactionID.uuidString, at: 2, to: statement)
                try bind(task.title, at: 3, to: statement)
                guard sqlite3_step(statement) == SQLITE_DONE else { throw error }
            }
    }

    func seedTasksIfEmpty(transactionID: UUID, titles: [String]) throws -> Int {
        try execute("BEGIN IMMEDIATE TRANSACTION;")
        do {
            let count = try withStatement(
                "SELECT COUNT(*) FROM checklist_tasks WHERE transaction_id=?;"
            ) { statement in
                try bind(transactionID.uuidString, at: 1, to: statement)
                guard sqlite3_step(statement) == SQLITE_ROW else { throw error }
                return Int(sqlite3_column_int(statement, 0))
            }
            if count != 0 {
                try execute("COMMIT;")
                return 0
            }
            for title in titles {
                try addTask(ChecklistItem(
                    id: UUID(), transactionID: transactionID,
                    title: title, isCompleted: false, linkedDocumentID: nil
                ))
            }
            try execute("COMMIT;")
            return titles.count
        } catch {
            try? execute("ROLLBACK;")
            throw error
        }
    }

    func renameTask(_ id: UUID, transactionID: UUID, title: String) throws {
        try withStatement("""
            UPDATE checklist_tasks SET title=? WHERE id=? AND transaction_id=?;
            """) { statement in
                try bind(title, at: 1, to: statement)
                try bind(id.uuidString, at: 2, to: statement)
                try bind(transactionID.uuidString, at: 3, to: statement)
                guard sqlite3_step(statement) == SQLITE_DONE else { throw error }
                guard sqlite3_changes(database) == 1 else {
                    throw DocumentProcessingError.invalidChecklistTask
                }
            }
    }

    func removeTask(_ id: UUID, transactionID: UUID) throws {
        try withStatement("""
            DELETE FROM checklist_tasks WHERE id=? AND transaction_id=?;
            """) { statement in
                try bind(id.uuidString, at: 1, to: statement)
                try bind(transactionID.uuidString, at: 2, to: statement)
                guard sqlite3_step(statement) == SQLITE_DONE else { throw error }
                guard sqlite3_changes(database) == 1 else {
                    throw DocumentProcessingError.invalidChecklistTask
                }
            }
    }

    func updateTask(_ taskID: UUID, transactionID: UUID, completed: Bool) throws {
        try withStatement("""
            UPDATE checklist_tasks SET completed=?
            WHERE id=? AND transaction_id=?;
            """) { statement in
                sqlite3_bind_int(statement, 1, completed ? 1 : 0)
                try bind(taskID.uuidString, at: 2, to: statement)
                try bind(transactionID.uuidString, at: 3, to: statement)
                guard sqlite3_step(statement) == SQLITE_DONE else { throw error }
                guard sqlite3_changes(database) == 1 else {
                    throw DocumentProcessingError.invalidChecklistTask
                }
            }
    }

    func linkDocument(
        _ documentID: UUID?, to taskID: UUID, transactionID: UUID
    ) throws {
        if let documentID {
            guard try documents(transactionID: transactionID).contains(
                where: { $0.id == documentID }
            ) else { throw DocumentProcessingError.missingDocument }
        }
        try withStatement("""
            UPDATE checklist_tasks SET linked_document_id=?
            WHERE id=? AND transaction_id=?;
            """) { statement in
                if let documentID {
                    try bind(documentID.uuidString, at: 1, to: statement)
                } else {
                    sqlite3_bind_null(statement, 1)
                }
                try bind(taskID.uuidString, at: 2, to: statement)
                try bind(transactionID.uuidString, at: 3, to: statement)
                guard sqlite3_step(statement) == SQLITE_DONE else { throw error }
                guard sqlite3_changes(database) == 1 else {
                    throw DocumentProcessingError.invalidChecklistTask
                }
            }
    }

    /// Additive and idempotent migration of old transaction checklists.
    private func addColumnIfNeeded(table: String, name: String, definition: String) throws {
        let names = try withStatement("PRAGMA table_info(\(table));") { statement -> Set<String> in
            var found = Set<String>()
            while true {
                let code = sqlite3_step(statement)
                if code == SQLITE_DONE { return found }
                guard code == SQLITE_ROW else { throw error }
                found.insert(text(statement, index: 1))
            }
        }
        if !names.contains(name) {
            try execute("ALTER TABLE \(table) ADD COLUMN \(name) \(definition);")
        }
    }

    private func execute(_ sql: String) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else { throw error }
    }

    private func withStatement<T>(
        _ sql: String, _ body: (OpaquePointer) throws -> T
    ) throws -> T {
        var raw: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &raw, nil) == SQLITE_OK,
              let raw else { throw error }
        defer { sqlite3_finalize(raw) }
        return try body(raw)
    }

    private func bind(_ value: String, at index: Int32, to statement: OpaquePointer) throws {
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let status = value.withCString {
            sqlite3_bind_text(statement, index, $0, -1, transient)
        }
        guard status == SQLITE_OK else { throw error }
    }

    private func text(_ statement: OpaquePointer, index: Int32) -> String {
        guard let value = sqlite3_column_text(statement, index) else { return "" }
        return String(cString: value)
    }

    private var error: DocumentProcessingError {
        DocumentProcessingError.database(
            database.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite error"
        )
    }
}
