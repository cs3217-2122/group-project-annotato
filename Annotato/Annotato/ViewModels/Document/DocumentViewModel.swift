import CoreGraphics
import Foundation
import AnnotatoSharedLibrary

class DocumentViewModel: ObservableObject {
    private let document: Document
    private(set) var annotations: [AnnotationViewModel]
    private(set) var pdfDocument: PdfViewModel

    @Published private(set) var annotationToAdd: AnnotationViewModel?

    init?(document: Document) {
        self.document = document
        self.annotations = document.annotations.map { AnnotationViewModel(annotation: $0) }

        guard let baseFileUrl = URL(string: document.baseFileUrl) else {
            return nil
        }

        self.pdfDocument = PdfViewModel(baseFileUrl: baseFileUrl)
    }
}

extension DocumentViewModel {
    func addAnnotation(center: CGPoint) {
        let newAnnotationWidth = 300.0
        let annotationViewModel = AnnotationViewModel(
            id: UUID(),
            origin: .zero,
            width: newAnnotationWidth,
            parts: []
        )
        annotationViewModel.center = center
        annotationViewModel.enterEditMode()
        annotationViewModel.enterMaximizedMode()
        annotations.append(annotationViewModel)
        annotationToAdd = annotationViewModel
    }
}
