import Foundation
import SQLite3

public struct OfficeProfile: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let createdAt: Date
}

/// Office rules are user-supplied settings, not legal determinations.
public enum OfficeTaskRequirement: String, CaseIterable, Sendable {
    case unspecified
    case required
    case optional
    public var displayName: String {
        switch self {
        case .unspecified: "Unspecified"
        case .required: "Office required"
        case .optional: "Office optional"
        }
    }
}
public struct OfficeTaskSpec: Equatable, Sendable {
    public var title: String
    public var requirement: OfficeTaskRequirement
    public var notes: String
    public init(title: String, requirement: OfficeTaskRequirement = .unspecified,
                notes: String = "") {
        self.title = title
        self.requirement = requirement
        self.notes = notes
    }
}
public struct OfficeChecklistTemplate: Equatable, Sendable {
    public let officeID: UUID
    public let workflow: WorkflowKind
    public let version: Int
    public let tasks: [OfficeTaskSpec]
    public var titles: [String] { tasks.map(\.title) }
}

public struct ChecklistSnapshot: Equatable, Sendable {
    public let transactionID: UUID
    public let officeID: UUID?
    public let officeName: String
    public let workflow: WorkflowKind
    public let templateVersion: Int
}

public enum OfficeTemplateError: Error, LocalizedError {
    case invalidOfficeName
    case duplicateOfficeName
    case missingOffice
    case invalidTasks
    case staleTemplate
    case invalidStoredData

    public var errorDescription: String? {
        switch self {
        case .invalidOfficeName: "Enter an office name between 1 and 120 characters."
        case .duplicateOfficeName: "An office with this name already exists."
        case .missingOffice: "The selected office no longer exists."
        case .invalidTasks: "Use 1–100 unique task titles (up to 250 characters) and notes (up to 500 characters)."
        case .staleTemplate: "The office checklist changed elsewhere. Reload before saving."
        case .invalidStoredData: "An office checklist record could not be read."
        }
    }
}

/// All template revisions are append-only. Transaction checklist rows and
/// provenance are inserted together in the same SQLite transaction.
final class OfficeTemplateStore {
    private var database: OpaquePointer?

    init(databaseURL: URL) throws {
        let code = sqlite3_open_v2(
            databaseURL.path, &database,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil
        )
        guard code == SQLITE_OK else {
            let reason = database.map { String(cString: sqlite3_errmsg($0)) } ?? "open failed"
            if let database { sqlite3_close(database) }
            database = nil
            throw DocumentProcessingError.database(reason)
        }
        sqlite3_busy_timeout(database, 3000)
        try execute("""
            PRAGMA foreign_keys=ON;
            CREATE TABLE IF NOT EXISTS office_profiles (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL COLLATE NOCASE UNIQUE,
                created_at REAL NOT NULL
            );
            CREATE TABLE IF NOT EXISTS office_template_versions (
                office_id TEXT NOT NULL,
                workflow TEXT NOT NULL,
                version INTEGER NOT NULL CHECK(version > 0),
                created_at REAL NOT NULL,
                PRIMARY KEY (office_id, workflow, version),
                FOREIGN KEY (office_id) REFERENCES office_profiles(id)
            );
            CREATE TABLE IF NOT EXISTS office_template_rows (
                office_id TEXT NOT NULL,
                workflow TEXT NOT NULL,
                version INTEGER NOT NULL,
                ordinal INTEGER NOT NULL,
                title TEXT NOT NULL,
                requirement TEXT NOT NULL DEFAULT 'unspecified',
                notes TEXT NOT NULL DEFAULT '',
                PRIMARY KEY (office_id, workflow, version, ordinal),
                FOREIGN KEY (office_id, workflow, version)
                    REFERENCES office_template_versions(office_id, workflow, version)
            );
            CREATE TABLE IF NOT EXISTS transaction_checklist_sources (
                transaction_id TEXT PRIMARY KEY NOT NULL,
                office_id TEXT,
                office_name TEXT NOT NULL,
                workflow TEXT NOT NULL,
                template_version INTEGER NOT NULL,
                created_at REAL NOT NULL
            );
            """)
        try addColumnIfNeeded(table: "office_template_rows", name: "requirement",
                              definition: "TEXT NOT NULL DEFAULT 'unspecified'")
        try addColumnIfNeeded(table: "office_template_rows", name: "notes",
                              definition: "TEXT NOT NULL DEFAULT ''")
    }

    deinit {
        if let database { sqlite3_close(database) }
    }

    func offices() throws -> [OfficeProfile] {
        try statement("""
            SELECT id, name, created_at FROM office_profiles
            ORDER BY name COLLATE NOCASE, id;
            """) { query in
                var result: [OfficeProfile] = []
                while true {
                    let status = sqlite3_step(query)
                    if status == SQLITE_DONE { return result }
                    guard status == SQLITE_ROW,
                          let id = UUID(uuidString: readText(query, 0))
                    else { throw OfficeTemplateError.invalidStoredData }
                    result.append(OfficeProfile(
                        id: id,
                        name: readText(query, 1),
                        createdAt: Date(timeIntervalSince1970: sqlite3_column_double(query, 2))
                    ))
                }
            }
    }

    @discardableResult
    func createOffice(named input: String) throws -> OfficeProfile {
        let name = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 120 else {
            throw OfficeTemplateError.invalidOfficeName
        }
        guard try !offices().contains(where: {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) else { throw OfficeTemplateError.duplicateOfficeName }
        let office = OfficeProfile(id: UUID(), name: name, createdAt: Date())
        try execute("BEGIN IMMEDIATE TRANSACTION;")
        do {
            try statement("""
                INSERT INTO office_profiles(id,name,created_at) VALUES (?,?,?);
                """) { query in
                    try bind(office.id.uuidString, at: 1, to: query)
                    try bind(office.name, at: 2, to: query)
                    sqlite3_bind_double(query, 3, office.createdAt.timeIntervalSince1970)
                    try done(query)
                }
            for workflow in WorkflowKind.allCases {
                let names = try StarterChecklist.titles(for: workflow)
                try insertRevision(
                    officeID: office.id, workflow: workflow, version: 1,
                    tasks: names.map { OfficeTaskSpec(title: $0) }
                )
            }
            try execute("COMMIT;")
            return office
        } catch {
            try? execute("ROLLBACK;")
            throw error
        }
    }

    func template(officeID: UUID, workflow: WorkflowKind) throws -> OfficeChecklistTemplate {
        let version = try statement("""
            SELECT MAX(version) FROM office_template_versions
            WHERE office_id=? AND workflow=?;
            """) { query -> Int? in
                try bind(officeID.uuidString, at: 1, to: query)
                try bind(workflow.rawValue, at: 2, to: query)
                guard sqlite3_step(query) == SQLITE_ROW else { throw error }
                guard sqlite3_column_type(query, 0) != SQLITE_NULL else { return nil }
                return Int(sqlite3_column_int(query, 0))
            }
        guard let version else { throw OfficeTemplateError.missingOffice }
        let tasks = try statement("""
            SELECT title, requirement, notes FROM office_template_rows
            WHERE office_id=? AND workflow=? AND version=?
            ORDER BY ordinal;
            """) { query in
                try bind(officeID.uuidString, at: 1, to: query)
                try bind(workflow.rawValue, at: 2, to: query)
                sqlite3_bind_int(query, 3, Int32(version))
                var rows: [OfficeTaskSpec] = []
                while true {
                    let status = sqlite3_step(query)
                    if status == SQLITE_DONE { return rows }
                    guard status == SQLITE_ROW,
                          let level = OfficeTaskRequirement(rawValue: readText(query, 1))
                    else { throw OfficeTemplateError.invalidStoredData }
                    rows.append(OfficeTaskSpec(
                        title: readText(query, 0), requirement: level, notes: readText(query, 2)
                    ))
                }
            }
        guard !tasks.isEmpty else { throw OfficeTemplateError.invalidStoredData }
        return OfficeChecklistTemplate(
            officeID: officeID, workflow: workflow, version: version, tasks: tasks
        )
    }

    /// Preserve metadata when legacy callers rearrange known title-only rows.
    @discardableResult
    func saveTemplate(
        officeID: UUID, workflow: WorkflowKind, expectedVersion: Int, titles input: [String]
    ) throws -> OfficeChecklistTemplate {
        let previous = try template(officeID: officeID, workflow: workflow)
        let tasks = input.map { title -> OfficeTaskSpec in
            let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if let found = previous.tasks.first(where: {
                $0.title.compare(clean, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }) {
                return OfficeTaskSpec(title: title, requirement: found.requirement, notes: found.notes)
            }
            return OfficeTaskSpec(title: title)
        }
        return try saveTemplate(officeID: officeID, workflow: workflow,
                                expectedVersion: expectedVersion, tasks: tasks)
    }

    @discardableResult
    func saveTemplate(
        officeID: UUID, workflow: WorkflowKind, expectedVersion: Int, tasks input: [OfficeTaskSpec]
    ) throws -> OfficeChecklistTemplate {
        let tasks = try validatedTasks(input)
        try execute("BEGIN IMMEDIATE TRANSACTION;")
        do {
            let current = try template(officeID: officeID, workflow: workflow)
            guard current.version == expectedVersion else { throw OfficeTemplateError.staleTemplate }
            if current.tasks != tasks {
                try insertRevision(
                    officeID: officeID, workflow: workflow,
                    version: current.version + 1, tasks: tasks
                )
            }
            try execute("COMMIT;")
            return try template(officeID: officeID, workflow: workflow)
        } catch {
            try? execute("ROLLBACK;")
            throw error
        }
    }

    /// Preserve an immutable source/identity record and task copies atomically.
    /// Never touch manually created rows or a previously initialized transaction.
    @discardableResult
    func seedTransaction(
        _ transactionID: UUID, workflow: WorkflowKind, officeID: UUID?
    ) throws -> Int {
        try execute("BEGIN IMMEDIATE TRANSACTION;")
        do {
            let count = try statement("""
                SELECT COUNT(*) FROM checklist_tasks WHERE transaction_id=?;
                """) { query in
                    try bind(transactionID.uuidString, at: 1, to: query)
                    guard sqlite3_step(query) == SQLITE_ROW else { throw error }
                    return Int(sqlite3_column_int(query, 0))
                }
            let previous = try snapshot(transactionID: transactionID)
            if count != 0 || previous != nil {
                try execute("COMMIT;")
                return 0
            }
            let tasks: [OfficeTaskSpec]
            let version: Int
            let officeName: String
            if let officeID {
                guard let office = try offices().first(where: { $0.id == officeID }) else {
                    throw OfficeTemplateError.missingOffice
                }
                let source = try template(officeID: officeID, workflow: workflow)
                tasks = source.tasks
                version = source.version
                officeName = office.name
            } else {
                tasks = try StarterChecklist.titles(for: workflow).map {
                    OfficeTaskSpec(title: $0)
                }
                version = 1
                officeName = "Built-in starter"
            }
            try statement("""
                INSERT INTO checklist_tasks(id,transaction_id,title,requirement,notes)
                VALUES (?,?,?,?,?);
                """) { query in
                    for task in tasks {
                        sqlite3_reset(query)
                        sqlite3_clear_bindings(query)
                        try bind(UUID().uuidString, at: 1, to: query)
                        try bind(transactionID.uuidString, at: 2, to: query)
                        try bind(task.title, at: 3, to: query)
                        try bind(task.requirement.rawValue, at: 4, to: query)
                        try bind(task.notes, at: 5, to: query)
                        try done(query)
                    }
                }
            try statement("""
                INSERT INTO transaction_checklist_sources
                    (transaction_id,office_id,office_name,workflow,template_version,created_at)
                VALUES (?,?,?,?,?,?);
                """) { query in
                    try bind(transactionID.uuidString, at: 1, to: query)
                    if let officeID {
                        try bind(officeID.uuidString, at: 2, to: query)
                    } else {
                        sqlite3_bind_null(query, 2)
                    }
                    try bind(officeName, at: 3, to: query)
                    try bind(workflow.rawValue, at: 4, to: query)
                    sqlite3_bind_int(query, 5, Int32(version))
                    sqlite3_bind_double(query, 6, Date().timeIntervalSince1970)
                    try done(query)
                }
            try execute("COMMIT;")
            return tasks.count
        } catch {
            try? execute("ROLLBACK;")
            throw error
        }
    }

    func snapshot(transactionID: UUID) throws -> ChecklistSnapshot? {
        try statement("""
            SELECT office_id,office_name,workflow,template_version
            FROM transaction_checklist_sources WHERE transaction_id=?;
            """) { query -> ChecklistSnapshot? in
                try bind(transactionID.uuidString, at: 1, to: query)
                let status = sqlite3_step(query)
                if status == SQLITE_DONE { return nil }
                guard status == SQLITE_ROW,
                      let workflow = WorkflowKind(rawValue: readText(query, 2))
                else { throw OfficeTemplateError.invalidStoredData }
                let officeID = sqlite3_column_type(query, 0) == SQLITE_NULL
                    ? nil : UUID(uuidString: readText(query, 0))
                return ChecklistSnapshot(
                    transactionID: transactionID, officeID: officeID,
                    officeName: readText(query, 1), workflow: workflow,
                    templateVersion: Int(sqlite3_column_int(query, 3))
                )
            }
    }

    private func validatedTasks(_ input: [OfficeTaskSpec]) throws -> [OfficeTaskSpec] {
        let tasks = input.map {
            OfficeTaskSpec(
                title: $0.title.trimmingCharacters(in: .whitespacesAndNewlines),
                requirement: $0.requirement,
                notes: $0.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        guard (1...100).contains(tasks.count),
              tasks.allSatisfy({
                  !$0.title.isEmpty && $0.title.count <= 250 &&
                  !$0.title.contains("\n") && !$0.title.contains("\r") &&
                  $0.notes.count <= 500
              }),
              Set(tasks.map {
                  $0.title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
              }).count == tasks.count
        else { throw OfficeTemplateError.invalidTasks }
        return tasks
    }

    private func insertRevision(
        officeID: UUID, workflow: WorkflowKind, version: Int, tasks: [OfficeTaskSpec]
    ) throws {
        try statement("""
            INSERT INTO office_template_versions(office_id,workflow,version,created_at)
            VALUES (?,?,?,?);
            """) { query in
                try bind(officeID.uuidString, at: 1, to: query)
                try bind(workflow.rawValue, at: 2, to: query)
                sqlite3_bind_int(query, 3, Int32(version))
                sqlite3_bind_double(query, 4, Date().timeIntervalSince1970)
                try done(query)
            }
        try statement("""
            INSERT INTO office_template_rows
                (office_id,workflow,version,ordinal,title,requirement,notes)
            VALUES (?,?,?,?,?,?,?);
            """) { query in
                for (position, task) in tasks.enumerated() {
                    sqlite3_reset(query)
                    sqlite3_clear_bindings(query)
                    try bind(officeID.uuidString, at: 1, to: query)
                    try bind(workflow.rawValue, at: 2, to: query)
                    sqlite3_bind_int(query, 3, Int32(version))
                    sqlite3_bind_int(query, 4, Int32(position))
                    try bind(task.title, at: 5, to: query)
                    try bind(task.requirement.rawValue, at: 6, to: query)
                    try bind(task.notes, at: 7, to: query)
                    try done(query)
                }
            }
    }

    /// Identifiers below are internal constants, never data from a workbook.
    private func addColumnIfNeeded(table: String, name: String, definition: String) throws {
        let names = try statement("PRAGMA table_info(\(table));") { query -> Set<String> in
            var found = Set<String>()
            while true {
                let code = sqlite3_step(query)
                if code == SQLITE_DONE { return found }
                guard code == SQLITE_ROW else { throw error }
                found.insert(readText(query, 1))
            }
        }
        if !names.contains(name) {
            try execute("ALTER TABLE \(table) ADD COLUMN \(name) \(definition);")
        }
    }

    private func execute(_ sql: String) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw error
        }
    }

    private func statement<T>(
        _ sql: String, _ body: (OpaquePointer) throws -> T
    ) throws -> T {
        var cursor: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &cursor, nil) == SQLITE_OK,
              let cursor else { throw error }
        defer { sqlite3_finalize(cursor) }
        return try body(cursor)
    }

    private func bind(_ value: String, at index: Int32, to query: OpaquePointer) throws {
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let result = value.withCString { sqlite3_bind_text(query, index, $0, -1, transient) }
        guard result == SQLITE_OK else { throw error }
    }

    private func done(_ query: OpaquePointer) throws {
        guard sqlite3_step(query) == SQLITE_DONE else { throw error }
    }

    private func readText(_ query: OpaquePointer, _ index: Int32) -> String {
        guard let value = sqlite3_column_text(query, index) else { return "" }
        return String(cString: value)
    }

    private var error: DocumentProcessingError {
        DocumentProcessingError.database(
            database.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite failure"
        )
    }
}
