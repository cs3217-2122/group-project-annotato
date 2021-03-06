import UIKit
import Combine

class DocumentListViewController: UIViewController, AlertPresentable, SpinnerPresentable {
    var webSocketManager: WebSocketManager?
    var presenter: DocumentListPresenter?

    let spinner = UIActivityIndicatorView(style: .large)
    private var toolbar = DocumentListToolbarView()
    private var importMenu = DocumentListImportMenuView()
    private var collectionView: DocumentListCollectionView?
    let toolbarHeight = 50.0
    private var cancellables: Set<AnyCancellable> = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        initializeToolbar()
        initializeDocumentsCollectionView()
        initializeImportMenu()
        setUpSubscribers()
        view.bringSubviewToFront(importMenu)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initializeSpinner()

        NetworkMonitor.shared.start()
    }

    private func initializeToolbar() {
        toolbar = DocumentListToolbarView(
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

    private func initializeImportMenu() {
        let width = 120.0
        let height = 80.0
        importMenu = DocumentListImportMenuView(frame: .zero)

        view.addSubview(importMenu)

        importMenu.translatesAutoresizingMaskIntoConstraints = false
        importMenu.topAnchor.constraint(equalTo: toolbar.bottomAnchor).isActive = true
        importMenu.rightAnchor.constraint(equalTo: margins.rightAnchor).isActive = true
        importMenu.widthAnchor.constraint(equalToConstant: width).isActive = true
        importMenu.heightAnchor.constraint(equalToConstant: height).isActive = true

        importMenu.isHidden = true
        importMenu.actionDelegate = self
    }

    private func initializeDocumentsCollectionView(inDeleteMode: Bool = false) {
        Task {
            guard let userId = AuthPresenter().currentUser?.id else {
                AnnotatoLogger.info("Could not get current user.",
                                    context: "DocumentListViewController::initializeSubviews")
                addDocumentsSubview(inDeleteMode: false)
                return
            }

            startSpinner()
            await presenter?.loadAllDocuments(userId: userId)
            stopSpinner()

            addDocumentsSubview(inDeleteMode: inDeleteMode)
        }
    }

    private func addDocumentsSubview(inDeleteMode: Bool) {
        guard let presenter = presenter else {
            return
        }

        collectionView?.removeFromSuperview()

        var initializeInDeleteMode = inDeleteMode
        if presenter.documents.isEmpty {
            initializeInDeleteMode = false
            toolbar.exitDeleteMode()
        }

        collectionView = DocumentListCollectionView(
            documents: presenter.documents,
            frame: .zero,
            documentListCollectionCellViewDelegate: self,
            initializeInDeleteMode: initializeInDeleteMode
        )

        guard let collectionView = collectionView else {
            return
        }

        view.addSubview(collectionView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.widthAnchor.constraint(equalToConstant: frame.width * 0.9).isActive = true
        collectionView.heightAnchor.constraint(equalToConstant: frame.height * 0.9).isActive = true
        collectionView.topAnchor.constraint(equalTo: margins.topAnchor, constant: toolbarHeight + 10.0).isActive = true
        collectionView.centerXAnchor.constraint(equalTo: margins.centerXAnchor).isActive = true
    }
}

extension DocumentListViewController: DocumentListToolbarDelegate,
        UIDocumentPickerDelegate,
        DocumentListCollectionCellViewDelegate,
        Navigable {

    func didTapLogOutButton() {
        presentWarningAlert(alertTitle: "Log Out",
                            warningMessage: "Are you sure you want to log out?", confirmHandler: { [weak self] in
            self?.webSocketManager?.resetSocket()
            AuthPresenter().logOut()
            self?.goToAuth(asNewRootViewController: true)
        })
    }

    func didTapImportFileButton() {
        importMenu.isHidden.toggle()

        if !importMenu.isHidden {
            view.bringSubviewToFront(importMenu)
        }
    }

    func didTapExitDeleteModeButton() {
        guard let collectionView = collectionView else {
            return
        }

        collectionView.exitDeleteMode()
        toolbar.exitDeleteMode()
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt baseFileUrls: [URL]) {
        guard let selectedFileUrl = baseFileUrls.first else {
            return
        }

        presenter?.importDocument(selectedFileUrl: selectedFileUrl) { [weak self] document in
            guard let document = document else {
                return
            }

            DispatchQueue.main.async {
                self?.goToDocumentEdit(documentId: document.id, webSocketManager: self?.webSocketManager)
            }
        }
    }

    func didSelectCellView(document: DocumentListCellPresenter) {
        goToDocumentEdit(documentId: document.id, webSocketManager: webSocketManager)
    }

    func didLongPressCellView() {
        guard let collectionView = collectionView else {
            return
        }

        collectionView.enterDeleteMode()
        toolbar.enterDeleteMode()
    }

    func didTapDeleteForEveryoneButton(document: DocumentListCellPresenter) {
        let warningMessage = "Are you sure you want to delete \(document.name)? " +
        "This deletes the document permanently for everyone"

        presentWarningAlert(
            alertTitle: "Confirm",
            warningMessage: warningMessage,
            confirmHandler: { [weak self] in
                self?.presenter?.deleteDocumentForEveryone(presenter: document)
            }
        )
    }

    func didTapDeleteAsNonOwner(document: DocumentListCellPresenter) {
        let warningMessage = "Are you sure you want to delete \(document.name)? " +
        "This deletes the document permanently for you"

        presentWarningAlert(
            alertTitle: "Confirm",
            warningMessage: warningMessage,
            confirmHandler: { [weak self] in
                self?.presenter?.deleteDocumentAsNonOwner(presenter: document)
            }
        )
    }

    func didTapChangeOwnerButton(document: DocumentListCellPresenter) {
        let documentPresenter = DocumentPresenter(webSocketManager: webSocketManager, model: document.document)
        goToUsersSharingDocumentList(document: documentPresenter, users: document.usersSharingDocument)
    }

    private func setUpSubscribers() {
        presenter?.$hasDeletedDocument.sink(receiveValue: { [weak self] hasDeletedDocument in
            if hasDeletedDocument {
                DispatchQueue.main.async {
                    guard let collectionView = self?.collectionView else {
                        return
                    }

                    self?.initializeDocumentsCollectionView(inDeleteMode: collectionView.isInDeleteMode)
                }
            }
        }).store(in: &cancellables)

        NetworkMonitor.shared.$isConnected.sink(receiveValue: { [weak self] isConnected in
            if isConnected {
                DispatchQueue.main.async {
                    guard let collectionView = self?.collectionView else {
                        return
                    }

                    self?.initializeDocumentsCollectionView(inDeleteMode: collectionView.isInDeleteMode)
                }
            }
        }).store(in: &cancellables)
    }
}

extension DocumentListViewController: DocumentListImportMenuDelegate {
    func didTapFromIpadButton() {
        goToImportingFiles()
    }

    func didTapFromCodeButton() {
        goToImportByCode()
    }
}
