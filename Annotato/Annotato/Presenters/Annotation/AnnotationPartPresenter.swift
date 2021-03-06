import Foundation
import CoreGraphics
import Combine
import AnnotatoSharedLibrary

class AnnotationPartPresenter: ObservableObject {
    weak var parentPresenter: AnnotationPresenter?

    var cancellables: Set<AnyCancellable> = []

    var model: AnnotationPart
    var origin: CGPoint
    var width: Double
    var id: UUID {
        model.id
    }
    var height: Double {
        model.height
    }

    @Published var isEditing = false
    @Published var isSelected = false
    @Published var isRemoved = false

    init(model: AnnotationPart, width: Double, origin: CGPoint = .zero) {
        self.model = model
        self.width = width
        self.origin = origin
    }

    func enterEditMode() {
        isEditing = true
    }

    func enterViewMode() {
        isEditing = false
    }

    // swiftlint:disable:next unavailable_function
    func toView() -> AnnotationPartView {
        fatalError("This method should be overridden by a concrete subclass")
    }
}

extension AnnotationPartPresenter {
    var size: CGSize {
        CGSize(width: width, height: height)
    }

    var frame: CGRect {
        CGRect(origin: origin, size: size)
    }

    func setHeight(to newHeight: Double) {
        model.setHeight(to: newHeight)
        parentPresenter?.resize()
    }

    func didSelect() {
        guard !isSelected else {
            return
        }

        parentPresenter?.setSelectedPart(to: self)
    }
}
