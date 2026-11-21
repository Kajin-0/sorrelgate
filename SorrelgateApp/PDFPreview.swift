import PDFKit
import SwiftUI

/// Native PDF viewer; an evidence link changes the requested page even when
/// the URL remains the same. Ordinary user scrolling does not snap back.
struct PDFPreview: NSViewRepresentable {
    let fileURL: URL
    let pageIndex: Int
    let navigationToken: UUID

    final class Coordinator {
        var lastFileURL: URL?
        var lastRequestedPageIndex: Int?
        var lastNavigationToken: UUID?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.backgroundColor = .textBackgroundColor
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        let documentChanged = context.coordinator.lastFileURL != fileURL
        if documentChanged {
            view.document = PDFDocument(url: fileURL)
            context.coordinator.lastFileURL = fileURL
            context.coordinator.lastRequestedPageIndex = nil
            context.coordinator.lastNavigationToken = nil
        }
        let requestedPageChanged = context.coordinator.lastRequestedPageIndex != pageIndex
            || context.coordinator.lastNavigationToken != navigationToken
        guard documentChanged || requestedPageChanged else { return }
        guard let document = view.document,
              pageIndex >= 0, pageIndex < document.pageCount,
              let page = document.page(at: pageIndex) else { return }
        view.go(to: page)
        context.coordinator.lastRequestedPageIndex = pageIndex
        context.coordinator.lastNavigationToken = navigationToken
    }
}
