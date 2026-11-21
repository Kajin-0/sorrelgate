import Foundation

public enum WorkflowKind: String, CaseIterable, Codable, Sendable {
    case listingPreparation
    case acceptedOffer

    public var displayName: String {
        switch self {
        case .listingPreparation: "Prepare a House for Sale"
        case .acceptedOffer: "Accepted Offer"
        }
    }
}

public struct TransactionRecord: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let propertyAddress: String
    public let workflow: WorkflowKind
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        propertyAddress: String,
        workflow: WorkflowKind,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.propertyAddress = propertyAddress
        self.workflow = workflow
        self.createdAt = createdAt
    }
}

public enum SorrelgateError: Error, LocalizedError {
    case invalidPropertyAddress
    case database(String)

    public var errorDescription: String? {
        switch self {
        case .invalidPropertyAddress:
            "Enter a property address to create a transaction."
        case .database(let detail):
            "The transaction database could not complete the operation: \(detail)"
        }
    }
}
