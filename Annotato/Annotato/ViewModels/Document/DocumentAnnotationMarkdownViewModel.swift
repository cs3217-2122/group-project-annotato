import UIKit

class DocumentAnnotationMarkdownViewModel: DocumentAnnotationTextViewModel {
    init(content: String, height: Double) {
        super.init(content: content, height: height, annotationType: .markdown)
    }

    override func toView<T>(in parentView: T) -> DocumentAnnotationSectionView where T: UIView {
        let frame = CGRect(x: .zero, y: .zero, width: parentView.frame.width, height: height)
        let view = DocumentAnnotationMarkdownView(frame: frame, textContainer: nil)
        view.text = content
        view.delegate = parentView as? DocumentAnnotationView
        return view
    }
}