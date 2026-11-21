import XCTest
@testable import SorrelgateCore

final class SorrelgateCoreTests: XCTestCase {
    private func temporaryDatabaseURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("SorrelgateCoreTests-\(UUID().uuidString)")
            .appendingPathComponent("records.sqlite")
    }

    func testCreateAndListTransactions() throws {
        let url = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let service = try SorrelgateService(store: SQLiteTransactionStore(fileURL: url))

        guard case .created(let created) = try service.execute(
            .createTransaction(propertyAddress: " 123 Example Street ", workflow: .acceptedOffer)
        ) else {
            return XCTFail("Expected created receipt")
        }
        XCTAssertEqual(created.propertyAddress, "123 Example Street")
        XCTAssertEqual(created.workflow, .acceptedOffer)

        guard case .transactions(let records) = try service.execute(.listTransactions) else {
            return XCTFail("Expected transaction list")
        }
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first, created)
    }

    func testRecordsSurviveStoreReopen() throws {
        let url = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let firstID: UUID
        do {
            let first = try SorrelgateService(store: SQLiteTransactionStore(fileURL: url))
            guard case .created(let transaction) = try first.execute(
                .createTransaction(propertyAddress: "42 Test Avenue", workflow: .listingPreparation)
            ) else { return XCTFail("Expected created transaction") }
            firstID = transaction.id
        }
        let reopened = try SorrelgateService(store: SQLiteTransactionStore(fileURL: url))
        guard case .transactions(let results) = try reopened.execute(.listTransactions) else {
            return XCTFail("Expected persisted transactions")
        }
        XCTAssertEqual(results.map(\.id), [firstID])
    }

    func testRejectsMissingAddressWithoutWriting() throws {
        let url = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let service = try SorrelgateService(store: SQLiteTransactionStore(fileURL: url))
        XCTAssertThrowsError(try service.execute(
            .createTransaction(propertyAddress: " \n ", workflow: .acceptedOffer)
        ))
        guard case .transactions(let records) = try service.execute(.listTransactions) else {
            return XCTFail("Expected list")
        }
        XCTAssertTrue(records.isEmpty)
    }

    func testAddressIsStoredAsDataNotSQL() throws {
        let url = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let service = try SorrelgateService(store: SQLiteTransactionStore(fileURL: url))
        let address = "7 O'Brien Lane'); DROP TABLE transactions; --"
        try service.execute(.createTransaction(propertyAddress: address, workflow: .acceptedOffer))
        guard case .transactions(let records) = try service.execute(.listTransactions) else {
            return XCTFail("Expected list")
        }
        XCTAssertEqual(records.first?.propertyAddress, address)
    }
}
