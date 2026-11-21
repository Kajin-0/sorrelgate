import Foundation

/// Pure, deterministic summary for an import that may partially succeed.
/// Completed documents are never reported as failures after an interruption.
public struct ImportBatchReport: Equatable, Sendable {
    public let imported: Int
    public let alreadyPresent: Int
    public let failed: Int
    public let cancelled: Bool

    public init(imported: Int, alreadyPresent: Int, failed: Int, cancelled: Bool) {
        self.imported = max(imported, 0)
        self.alreadyPresent = max(alreadyPresent, 0)
        self.failed = max(failed, 0)
        self.cancelled = cancelled
    }

    public var summary: String {
        var parts = ["Imported \(imported) \(imported == 1 ? "PDF" : "PDFs")."]
        if alreadyPresent > 0 {
            parts.append("\(alreadyPresent) already imported.")
        }
        if failed > 0 {
            parts.append("\(failed) couldn't be imported.")
        }
        if cancelled {
            parts.append("Import stopped. Completed PDFs were kept.")
        }
        return parts.joined(separator: " ")
    }

    public static func failure(filename: String, reason: String) -> String {
        // PDF-specific errors already identify the filename. Don't repeat it.
        let clean = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.localizedCaseInsensitiveContains(filename)
            ? clean : "\(filename): \(clean)"
    }

    public static func conciseFailures(_ failures: [String], limit: Int = 4) -> String {
        let shown = failures.prefix(max(0, limit)).joined(separator: "\n")
        let hidden = failures.count - min(failures.count, max(0, limit))
        if hidden == 0 { return shown }
        return shown + "\nAnd \(hidden) more \(hidden == 1 ? "error" : "errors")."
    }
}
