import Foundation
import SQLite3

/// Small, synchronous local persistence boundary. Call through SorrelgateService,
/// not from SwiftUI views or LLM tool handlers. Later migrations can extend this.
public final class SQLiteTransactionStore {
    private var database: OpaquePointer?

    public init(fileURL: URL) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let status = sqlite3_open_v2(
            fileURL.path,
            &database,
            SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil
        )
        guard status == SQLITE_OK else {
            let reason = Self.message(from: database)
            if let database { sqlite3_close(database) }
            database = nil
            throw SorrelgateError.database(reason)
        }

        sqlite3_busy_timeout(database, 3000)
        try executeSQL("PRAGMA journal_mode = WAL;")
        try executeSQL("""
            CREATE TABLE IF NOT EXISTS transactions (
                id TEXT PRIMARY KEY NOT NULL,
                property_address TEXT NOT NULL,
                workflow TEXT NOT NULL,
                created_at REAL NOT NULL
            );
            """)
        try executeSQL("PRAGMA user_version = 1;")
    }

    deinit {
        if let database {
            sqlite3_close(database)
        }
    }

    public func insert(_ transaction: TransactionRecord) throws {
        try withStatement("""
            INSERT INTO transactions (id, property_address, workflow, created_at)
            VALUES (?, ?, ?, ?);
            """) { statement in
                try bind(transaction.id.uuidString, index: 1, in: statement)
                try bind(transaction.propertyAddress, index: 2, in: statement)
                try bind(transaction.workflow.rawValue, index: 3, in: statement)
                guard sqlite3_bind_double(
                    statement, 4, transaction.createdAt.timeIntervalSince1970
                ) == SQLITE_OK else {
                    throw SorrelgateError.database(databaseMessage)
                }
                guard sqlite3_step(statement) == SQLITE_DONE else {
                    throw SorrelgateError.database(databaseMessage)
                }
            }
    }

    public func list() throws -> [TransactionRecord] {
        try withStatement("""
            SELECT id, property_address, workflow, created_at
            FROM transactions ORDER BY created_at DESC, id DESC;
            """) { statement in
                var records: [TransactionRecord] = []
                while true {
                    let result = sqlite3_step(statement)
                    if result == SQLITE_DONE { return records }
                    guard result == SQLITE_ROW else {
                        throw SorrelgateError.database(databaseMessage)
                    }
                    guard
                        let idCString = sqlite3_column_text(statement, 0),
                        let addressCString = sqlite3_column_text(statement, 1),
                        let workflowCString = sqlite3_column_text(statement, 2),
                        let id = UUID(uuidString: String(cString: idCString)),
                        let workflow = WorkflowKind(rawValue: String(cString: workflowCString))
                    else {
                        throw SorrelgateError.database("Stored transaction fields are invalid.")
                    }
                    records.append(TransactionRecord(
                        id: id,
                        propertyAddress: String(cString: addressCString),
                        workflow: workflow,
                        createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
                    ))
                }
            }
    }

    private func executeSQL(_ sql: String) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw SorrelgateError.database(databaseMessage)
        }
    }

    private func withStatement<T>(
        _ sql: String,
        body: (OpaquePointer) throws -> T
    ) throws -> T {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw SorrelgateError.database(databaseMessage)
        }
        defer { sqlite3_finalize(statement) }
        return try body(statement)
    }

    private func bind(_ value: String, index: Int32, in statement: OpaquePointer) throws {
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let status = value.withCString {
            sqlite3_bind_text(statement, index, $0, -1, transient)
        }
        guard status == SQLITE_OK else {
            throw SorrelgateError.database(databaseMessage)
        }
    }

    private var databaseMessage: String {
        Self.message(from: database)
    }

    private static func message(from database: OpaquePointer?) -> String {
        guard let database, let pointer = sqlite3_errmsg(database) else {
            return "Unknown SQLite error."
        }
        return String(cString: pointer)
    }
}
