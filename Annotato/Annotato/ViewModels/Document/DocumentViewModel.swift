import CoreGraphics
import Foundation
import AnnotatoSharedLibrary
import Combine

class DocumentViewModel: ObservableObject {
    let model: Document

    private(set) var annotations: [AnnotationViewModel] = []
    private(set) var pdfDocument: PdfViewModel

    @Published private(set) var addedAnnotation: AnnotationViewModel?

    init?(model: Document) {
        guard let baseFileUrl = URL(string: model.baseFileUrl) else {
            return nil
        }

        self.model = model
        self.pdfDocument = PdfViewModel(baseFileUrl: baseFileUrl)
        self.annotations = model.annotations.map { AnnotationViewModel(model: $0, document: self) }
    }
}

extension DocumentViewModel {
    func addAnnotationIfWithinBounds(center: CGPoint, bounds: CGRect) {
        guard let currentUser = AnnotatoAuth().currentUser else {
            return
        }

        let newAnnotationWidth = 300.0
        let newAnnotation = Annotation(
            origin: .zero,
            width: newAnnotationWidth,
            parts: [],
            ownerId: currentUser.uid,
            documentId: model.id,
            id: UUID()
        )
        model.addAnnotation(annotation: newAnnotation)

        let annotationViewModel = AnnotationViewModel(model: newAnnotation, document: self)
        annotationViewModel.center = center

        if annotationViewModel.hasExceededBounds(bounds: bounds) {
            model.removeAnnotation(annotation: newAnnotation)
            return
        }

        annotationViewModel.enterEditMode()
        annotationViewModel.enterMaximizedMode()
        annotations.append(annotationViewModel)
        addedAnnotation = annotationViewModel
    }

    func removeAnnotation(annotation: AnnotationViewModel) {
        model.removeAnnotation(annotation: annotation.model)
        annotations.removeAll(where: { $0 === annotation })
    }
}
