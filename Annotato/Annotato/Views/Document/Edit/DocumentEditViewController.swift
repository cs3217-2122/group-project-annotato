import UIKit
import Combine

class DocumentEditViewController: UIViewController, AlertPresentable, SpinnerPresentable {
    var webSocketManager: WebSocketManager?

    let spinner = UIActivityIndicatorView(style: .large)
    var documentId: UUID?
    let toolbarHeight = 50.0
    var presenter: DocumentPresenter?
    private var documentView: DocumentView?
    private var cancellables: Set<AnyCancellable> = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        presenter = DocumentPresenter(webSocketManager: webSocketManager)
        initializeSubviews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNetworkSubscriber()
    }

    func initializeSubviews() {
        initializeSpinner()

        initializeToolbar()

        Task {
            guard let documentId = documentId else {
                return
            }

            startSpinner()
            await presenter?.loadDocumentWithDeleted(documentId: documentId)
            setUpSubscribers()
            stopSpinner()

            initializeDocumentView()
        }
    }

    private func initializeToolbar() {
        let toolbar = DocumentEditToolbarView(
            frame: CGRect(x: .zero, y: .zero, width: frame.width, height: toolbarHeight)
        )
        toolbar.actionDelegate = self

        view.addSubview(toolbar)

        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.widthAnchor.constraint(equalToConstant: frame.width).isActive = true
        toolbar.heightAnchor.constraint(equalToConstant: toolbarHeight).isActive = true
        toolbar.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        toolbar.centerXAnchor.constraint(equalTo: margins.centerXAnchor).isActive = true
    }

    private func initializeDocumentView() {
        guard let documentPresenter = presenter else {
            presentErrorAlert(errorMessage: "Failed to load document.")
            return
        }

        documentView?.removeFromSuperview()

        documentView = DocumentView(
            frame: self.view.safeAreaLayoutGuide.layoutFrame,
            documentPresenter: documentPresenter
        )

        guard let documentView = documentView else {
            return
        }

        view.addSubview(documentView)

        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.topAnchor.constraint(
            equalTo: margins.topAnchor, constant: toolbarHeight).isActive = true
        documentView.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
        documentView.leftAnchor.constraint(equalTo: margins.leftAnchor).isActive = true
        documentView.rightAnchor.constraint(equalTo: margins.rightAnchor).isActive = true
    }

    private func alertUsersToLeaveDocument() {
        presentInfoAlert(
            alertTitle: "Notice",
            message: "The document has been permanently deleted, " +
            "please contact the owner if there seems to be a mistake",
            confirmHandler: { [weak self] in
                self?.goBack()
            }
        )
    }
}

extension DocumentEditViewController: DocumentEditToolbarDelegate, Navigable {
    func didTapBackButton() {
        goBack()
    }

    func didTapShareButton() {
        guard let documentId = documentId else {
            return
        }
        goToShare(documentId: documentId)
    }
}

extension DocumentEditViewController {
    private func setUpNetworkSubscriber() {
        NetworkMonitor.shared.$isConnected.sink(receiveValue: { [weak self] _ in
            guard let self = self else {
                return
            }

            DispatchQueue.main.async {
                self.viewWillAppear(false)
            }
        }).store(in: &cancellables)
    }

    private func setUpSubscribers() {
        presenter?.$hasUpdatedDocument.sink(receiveValue: { [weak self] hasUpdatedDocument in
            if hasUpdatedDocument {
                DispatchQueue.main.async {
                    self?.initializeDocumentView()
                }
            }
        }).store(in: &cancellables)

        presenter?.$hasDeletedDocument.sink(receiveValue: { [weak self] hasDeletedDocument in
            if hasDeletedDocument {
                DispatchQueue.main.async {
                    self?.alertUsersToLeaveDocument()
                }
            }
        }).store(in: &cancellables)
    }
}
