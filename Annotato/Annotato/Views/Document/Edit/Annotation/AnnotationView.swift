import UIKit
import Combine

class AnnotationView: UIView {
    private(set) var viewModel: AnnotationViewModel

    private var palette: AnnotationPaletteView
    private var scroll: UIScrollView
    private var parts: UIStackView
    private var cancellables: Set<AnyCancellable> = []

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(viewModel: AnnotationViewModel) {
        self.viewModel = viewModel
        self.palette = AnnotationPaletteView(viewModel: viewModel.palette)
        self.scroll = UIScrollView(frame: viewModel.scrollFrame)
        self.parts = UIStackView(frame: viewModel.partsFrame)
        super.init(frame: viewModel.frame)
        initializeSubviews()
        setUpSubscriber()
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.systemBlue.cgColor
    }

    private func initializeSubviews() {
        addSubview(palette)
        setUpScrollAndParts()
        populateParts()
    }

    private func setUpScrollAndParts() {
        addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        scroll.topAnchor.constraint(equalTo: palette.bottomAnchor).isActive = true
        scroll.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        scroll.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        parts.axis = .vertical
        scroll.addSubview(parts)
        parts.leadingAnchor.constraint(equalTo: scroll.leadingAnchor).isActive = true
        parts.trailingAnchor.constraint(equalTo: scroll.trailingAnchor).isActive = true
        parts.bottomAnchor.constraint(equalTo: scroll.bottomAnchor).isActive = true
        parts.topAnchor.constraint(equalTo: scroll.topAnchor).isActive = true
        parts.widthAnchor.constraint(equalTo: scroll.widthAnchor).isActive = true
    }

    private func populateParts() {
        for partViewModel in viewModel.parts {
            parts.addArrangedSubview(partViewModel.toView())
        }
    }

    private func setUpSubscriber() {
        viewModel.$isResizing.sink(receiveValue: { [weak self] _ in
            self?.resize()
        }).store(in: &cancellables)

        viewModel.$partToAppend.sink(receiveValue: { [weak self] partViewModel in
            guard let partViewModel = partViewModel else {
                return
            }
            self?.parts.addArrangedSubview(partViewModel.toView())
        }).store(in: &cancellables)
    }

    private func resize() {
        parts.frame = viewModel.partsFrame
        self.frame = viewModel.frame
    }
}
