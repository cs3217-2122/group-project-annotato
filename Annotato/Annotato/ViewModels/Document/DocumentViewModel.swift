import CoreGraphics
import Foundation
import AnnotatoSharedLibrary
import Combine

class DocumentViewModel: ObservableObject {
    let model: Document

    private(set) var annotations: [AnnotationViewModel] = []
    private(set) var pdfDocument: PdfViewModel
    private var selectionStartPoint: CGPoint?
    private var selectionEndPoint: CGPoint?

    @Published private(set) var addedAnnotation: AnnotationViewModel?
    @Published private(set) var selectionBoxFrame: CGRect?
    @Published private(set) var connectivityChanged = false

    private var cancellables: Set<AnyCancellable> = []

    init(model: Document) {
        self.model = model
        self.pdfDocument = PdfViewModel(document: model)
        self.annotations = model.annotations
            .filter { !$0.isDeleted }
            .map { AnnotationViewModel(model: $0, document: self) }
        setUpSubscribers()
    }

    func setUpSubscribers() {
        NetworkMonitor.shared.$isConnected.sink(receiveValue: { [weak self] isConnected in
            guard let self = self else {
                return
            }
            // Call document to reset all the annotations that it contains, calling on local and remote as per needed
            // by doing something like model.resetAnnotation(connectivityStatus: Bool)
            if isConnected {
                // MARK: Reset the annotations to take from remote, take from local, and compare, then
                // reset the annotations array
            } else {
                // MARK: User went offline, so only display the annotations from local, without the merge conflicts
                // additional annotations that we created. All annotations should not have the merge conflict palette
            }

            // Only after that is done, then set the published boolean to get the document view to reload annotations
            self.connectivityChanged = true
        }).store(in: &cancellables)
    }

    func setAllAnnotationsOutOfFocus() {
        for annotation in annotations {
            annotation.outOfFocus()
        }
    }

    func setAllOtherAnnotationsOutOfFocus(except annotationInFocus: AnnotationViewModel) {
        for annotation in annotations where annotation.id != annotationInFocus.id {
            annotation.outOfFocus()
        }
    }
}

extension DocumentViewModel {
    func setSelectionBoxStartPoint(point: CGPoint) {
        selectionStartPoint = point
        updateSelectionBoxFrame()
    }

    func setSelectionBoxEndPoint(point: CGPoint) {
        selectionEndPoint = point
        updateSelectionBoxFrame()
    }

    private func updateSelectionBoxFrame() {
        guard let selectionStartPoint = selectionStartPoint,
              let selectionEndPoint = selectionEndPoint else {
            selectionBoxFrame = nil
            return
        }

        selectionBoxFrame = CGRect(startPoint: selectionStartPoint, endPoint: selectionEndPoint)
    }

    private func resetSelectionPoints() {
        selectionStartPoint = nil
        selectionEndPoint = nil
        selectionBoxFrame = nil
    }

    func addAnnotation(bounds: CGRect) {
        guard let selectionStartPoint = selectionStartPoint,
              let selectionEndPoint = selectionEndPoint,
              let selectionBoxFrame = selectionBoxFrame,
              let currentUser = AnnotatoAuth().currentUser else {
            return
        }

        resetSelectionPoints()

        let annotationId = UUID()
        let annotationWidth = 300.0
        let selectionBox = SelectionBox(startPoint: selectionStartPoint,
                                        endPoint: selectionEndPoint,
                                        annotationId: annotationId)

        let newAnnotation = Annotation(
            origin: selectionBoxFrame.center,
            width: annotationWidth,
            parts: [],
            selectionBox: selectionBox,
            ownerId: currentUser.uid,
            documentId: model.id,
            id: annotationId
        )

        model.addAnnotation(annotation: newAnnotation)

        let annotationViewModel = AnnotationViewModel(model: newAnnotation, document: self)
        if annotationViewModel.hasExceededBounds(bounds: bounds) {
            let boundsMidX = bounds.midX
            let annotationY = annotationViewModel.frame.midY
            annotationViewModel.center = CGPoint(x: boundsMidX, y: annotationY)
        }

        annotationViewModel.enterEditMode()
        annotationViewModel.enterMaximizedMode()

        annotations.append(annotationViewModel)
        addedAnnotation = annotationViewModel

        Task {
            await AnnotatoPersistenceWrapper.currentPersistenceService.createAnnotation(annotation: newAnnotation)
        }
    }

    func receiveNewAnnotation(newAnnotation: Annotation) {
        guard !newAnnotation.isDeleted else {
            return
        }

        self.model.addAnnotation(annotation: newAnnotation)
        let annotationViewModel = AnnotationViewModel(model: newAnnotation, document: self)
        self.annotations.append(annotationViewModel)
        self.addedAnnotation = annotationViewModel
    }

    func receiveUpdateAnnotation(updatedAnnotation: Annotation) {
        if let annotationViewModel = annotations.first(where: { $0.id == updatedAnnotation.id }) {
            if updatedAnnotation.isDeleted {
                receiveDeleteAnnotation(deletedAnnotation: updatedAnnotation)
            } else {
                annotationViewModel.receiveUpdate(updatedAnnotation: updatedAnnotation)
            }
        } else {
            receiveRestoreDeletedAnnotation(annotation: updatedAnnotation)
        }
    }

    private func receiveRestoreDeletedAnnotation(annotation: Annotation) {
        model.receiveRestoreDeletedAnnotation(annotation: annotation)
        let annotationViewModel = AnnotationViewModel(model: annotation, document: self)
        self.annotations.append(annotationViewModel)
        self.addedAnnotation = annotationViewModel
    }

    func removeAnnotation(annotation: AnnotationViewModel) {
        model.removeAnnotation(annotation: annotation.model)
        annotations.removeAll(where: { $0.id == annotation.model.id })

        Task {
            await AnnotatoPersistenceWrapper.currentPersistenceService.deleteAnnotation(annotation: annotation.model)
        }
    }

    func receiveDeleteAnnotation(deletedAnnotation: Annotation) {
        guard deletedAnnotation.isDeleted else {
            return
        }

        model.removeAnnotation(annotation: deletedAnnotation)
        let annotationViewModel = annotations.first(where: { $0.id == deletedAnnotation.id })
        annotationViewModel?.receiveDelete()
        annotations.removeAll(where: { $0.model.id == deletedAnnotation.id })
    }
}
