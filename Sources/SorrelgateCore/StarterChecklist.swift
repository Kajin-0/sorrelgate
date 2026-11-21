import Foundation

/// Editable administrative starter tasks, not legal/compliance rules.
public enum StarterChecklist {
    private struct Catalog: Decodable {
        let schema_version: Int
        let workflows: [Workflow]
    }
    private struct Workflow: Decodable {
        let key: String
        let tasks: [Entry]
    }
    private struct Entry: Decodable {
        let key: String
        let name: String
    }
    public enum CatalogError: Error, LocalizedError {
        case missingResource, unsupportedVersion, malformed
        public var errorDescription: String? {
            switch self {
            case .missingResource: "The starter checklist is missing."
            case .unsupportedVersion: "The starter checklist version is unsupported."
            case .malformed: "The starter checklist contains incomplete tasks."
            }
        }
    }
    public static func titles(for kind: WorkflowKind) throws -> [String] {
        guard let url = Bundle.module.url(
            forResource: "CA_SELLER_SIDE_STARTER", withExtension: "json"
        ) else { throw CatalogError.missingResource }
        let data = try Data(contentsOf: url)
        let catalog = try JSONDecoder().decode(Catalog.self, from: data)
        guard catalog.schema_version == 1 else { throw CatalogError.unsupportedVersion }
        let key: String
        switch kind {
        case .listingPreparation: key = "seller_listing_preparation"
        case .acceptedOffer: key = "seller_accepted_offer"
        }
        guard let workflow = catalog.workflows.first(where: { $0.key == key }),
              !workflow.tasks.isEmpty else { throw CatalogError.malformed }
        let names = workflow.tasks.map {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let keys = workflow.tasks.map(\.key)
        guard names.allSatisfy({ !$0.isEmpty && $0.count <= 250 }),
              keys.allSatisfy({ !$0.isEmpty }), Set(keys).count == keys.count
        else { throw CatalogError.malformed }
        return names
    }
}
