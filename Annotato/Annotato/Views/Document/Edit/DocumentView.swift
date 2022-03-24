import UIKit
import PDFKit
import Combine

class DocumentView: UIView {
    private var viewModel: DocumentViewModel
    private var cancellables: Set<AnyCancellable> = []

    private var pdfView: DocumentPdfView
    private var annotationViews: [AnnotationView]
    private var selectionBoxViews: [SelectionBoxView]
    private var linkLineViews: [LinkLineView]

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, documentViewModel: DocumentViewModel) {
        self.viewModel = documentViewModel
        self.annotationViews = []
        self.selectionBoxViews = []
        self.linkLineViews = []
        self.pdfView = DocumentPdfView(
            frame: .zero,
            documentPdfViewModel: documentViewModel.pdfDocument
        )

        super.init(frame: frame)

        addGestureRecognizers()
        addObservers()
        initializePdfView()
        setUpSubscribers()
        initializeInitialAnnotationViews()
    }

    private func initializeInitialAnnotationViews() {
        for annotation in viewModel.annotations {
            renderNewAnnotation(viewModel: annotation)
        }
    }

    private func initializePdfView() {
        addSubview(pdfView)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        pdfView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        pdfView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }

    private func setUpSubscribers() {
        viewModel.$addedAnnotation.sink(receiveValue: { [weak self] addedAnnotation in
            guard let addedAnnotation = addedAnnotation else {
                return
            }
            self?.renderNewAnnotation(viewModel: addedAnnotation)
        }).store(in: &cancellables)

        viewModel.$addedSelectionBox.sink(receiveValue: { [weak self] addedSelectionBox in
            guard let addedSelectionBox = addedSelectionBox else {
                return
            }
            self?.renderNewSelectionBox(viewModel: addedSelectionBox)
        }).store(in: &cancellables)
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(didChangeVisiblePages(notification:)),
            name: Notification.Name.PDFViewVisiblePagesChanged, object: nil
        )
    }

    @objc
    private func didChangeVisiblePages(notification: Notification) {
        showAnnotationsOfVisiblePages()
        showSelectionBoxedOfVisiblePages()
        showLinkLinesOfVisiblePages()
    }

    private func addGestureRecognizers() {
        isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tapGestureRecognizer)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        addGestureRecognizer(panGestureRecognizer)
    }

    @objc
    private func didPan(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            let startPoint = sender.location(in: self)
            addSelectionBoxIfWithinBounds(at: startPoint)
        }
        if sender.state != .cancelled {
            let currentTouchPoint = sender.location(in: self)
            updateCurrentSelectionBoxIfWithinBounds(newEndPointInDocument: currentTouchPoint)
        }
        if sender.state == .ended {
            let currentTouchPoint = sender.location(in: self)
            updateCurrentSelectionBoxIfWithinBounds(newEndPointInDocument: currentTouchPoint)
            addAnnotationWithAssociatedSelectionBoxIfWithinBounds()
        }
    }

    @objc
    private func didTap(_ sender: UITapGestureRecognizer) {
        let touchPoint = sender.location(in: self)
        addAnnotationIfWithinPdfBounds(at: touchPoint)
    }
}

// MARK: Adding new selection box/updating selection box
extension DocumentView {
    private func addSelectionBoxIfWithinBounds(at pointInDocument: CGPoint) {
        guard let pdfInnerDocumentView = pdfView.documentView else {
            return
        }
        let pointInPdf = self.convert(pointInDocument, to: pdfView.documentView)
        viewModel.addSelectionBoxIfWithinBounds(startPoint: pointInPdf, bounds: pdfInnerDocumentView.bounds)
    }

    private func updateCurrentSelectionBoxIfWithinBounds(newEndPointInDocument: CGPoint) {
        guard let pdfInnerDocumentView = pdfView.documentView else {
            return
        }
        let pointInPdf = self.convert(newEndPointInDocument, to: pdfView.documentView)
        viewModel.updateCurrentSelectionBoxEndPoint(newEndPoint: pointInPdf, bounds: pdfInnerDocumentView.bounds)
    }

    private func renderNewSelectionBox(viewModel: SelectionBoxViewModel) {
        let selectionBoxView = SelectionBoxView(viewModel: viewModel)
        selectionBoxViews.append(selectionBoxView)
        pdfView.documentView?.addSubview(selectionBoxView)
    }
}

// MARK: Adding new annotations
extension DocumentView {
    private func renderNewAnnotation(viewModel: AnnotationViewModel) {
        let annotationView = AnnotationView(viewModel: viewModel)
        guard let linkLineViewModel = viewModel.linkLine else {
            return
        }
        let linkLineView = LinkLineView(viewModel: linkLineViewModel)
        annotationViews.append(annotationView)
        linkLineViews.append(linkLineView)

        pdfView.documentView?.addSubview(annotationView)
        pdfView.documentView?.addSubview(linkLineView)
    }

    private func addAnnotationIfWithinPdfBounds(at pointInDocument: CGPoint) {
        let pointInPdf = self.convert(pointInDocument, to: pdfView.documentView)
        guard let pdfInnerDocumentView = pdfView.documentView else {
            return
        }
        viewModel.addAnnotationIfWithinBounds(center: pointInPdf, bounds: pdfInnerDocumentView.bounds)
    }

    private func addAnnotationWithAssociatedSelectionBoxIfWithinBounds() {
        guard let pdfInnerDocumentView = pdfView.documentView else {
            return
        }
        viewModel.addAnnotationWithAssociatedSelectionBoxIfWithinBounds(bounds: pdfInnerDocumentView.bounds)
    }
}

// MARK: Display annotations, selection boxes and link lines when visible pages of pdf change
extension DocumentView {
    // Note: Subviews in PdfView get shifted to the back after scrolling away
    // for a certain distance, therefore they must be brought forward
    private func showAnnotationsOfVisiblePages() {
        let visiblePages = pdfView.visiblePages

        let annotationsToShow = annotationViews.filter({
            annotationIsInVisiblePages(annotation: $0, visiblePages: visiblePages)
        })
        for annotation in annotationsToShow {
            bringAnnotationToFront(annotation: annotation)
        }
    }

    private func showSelectionBoxedOfVisiblePages() {
        let visiblePages = pdfView.visiblePages

        let selectionBoxesToShow = selectionBoxViews.filter({
            selectionBoxIsInVisiblePages(selectionBox: $0, visiblePages: visiblePages)
        })
        for selectionBox in selectionBoxesToShow {
            bringSelectionBoxToFront(selectionBox: selectionBox)
        }
    }

    private func showLinkLinesOfVisiblePages() {
        let visiblePages = pdfView.visiblePages
        let linkLinesToShow = linkLineViews.filter({
            linkLineIsInVisiblePages(linkLine: $0, visiblePages: visiblePages)
        })
        for linkLine in linkLinesToShow {
            bringLinkLineToFront(linkLine: linkLine)
        }
    }

    private func annotationIsInVisiblePages(
        annotation: AnnotationView,
        visiblePages: [PDFPage]
    ) -> Bool {
        guard let centerInDocument = pdfView.documentView?.convert(annotation.center, to: self) else {
            return false
        }
        guard let pageContainingAnnotation = pdfView.page(for: centerInDocument, nearest: true) else {
            return false
        }
        return visiblePages.contains(pageContainingAnnotation)
    }

    private func selectionBoxIsInVisiblePages(selectionBox: SelectionBoxView, visiblePages: [PDFPage]) -> Bool {
        guard let centerInDocument = pdfView.documentView?.convert(selectionBox.center, to: self) else {
            return false
        }
        guard let pageContainingSelectionBox = pdfView.page(for: centerInDocument, nearest: true) else {
            return false
        }
        return visiblePages.contains(pageContainingSelectionBox)
    }

    private func linkLineIsInVisiblePages(linkLine: LinkLineView, visiblePages: [PDFPage]) -> Bool {
        guard let centerInDocument = pdfView.documentView?.convert(linkLine.center, to: self) else {
            return false
        }
        guard let pageContainingLinkLine = pdfView.page(for: centerInDocument, nearest: true) else {
            return false
        }
        return visiblePages.contains(pageContainingLinkLine)
    }

    private func bringAnnotationToFront(annotation: AnnotationView) {
        annotation.superview?.bringSubviewToFront(annotation)
    }

    private func bringSelectionBoxToFront(selectionBox: SelectionBoxView) {
        selectionBox.superview?.bringSubviewToFront(selectionBox)
    }

    private func bringLinkLineToFront(linkLine: LinkLineView) {
        linkLine.superview?.bringSubviewToFront(linkLine)
    }
}
