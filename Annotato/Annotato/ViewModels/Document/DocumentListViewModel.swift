import Foundation
import AnnotatoSharedLibrary
import Combine

class DocumentListViewModel {
    private let documentsPersistenceManager: DocumentsPersistenceManager
    private let documentSharesPersistenceManager: DocumentSharesPersistenceManager
    private let pdfStorageManager = PDFStorageManager()

    private(set) var documents: [DocumentListCellViewModel] = []
    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var hasDeletedDocument = false

    init(webSocketManager: WebSocketManager?) {
        self.documentsPersistenceManager = DocumentsPersistenceManager(webSocketManager: webSocketManager)
        self.documentSharesPersistenceManager = DocumentSharesPersistenceManager()

        setUpSubscribers()
    }

    func loadAllDocuments(userId: String) async -> [DocumentListCellViewModel] {
        let ownDocuments = await documentsPersistenceManager.getOwnDocuments(userId: userId) ?? []
        let sharedDocuments = await documentsPersistenceManager.getSharedDocuments(userId: userId) ?? []

        let ownDocumentViewModels = ownDocuments.filter { !$0.isDeleted }
            .map { DocumentListCellViewModel(document: $0, isShared: false) }
        let sharedDocumentViewModels = sharedDocuments.filter { !$0.isDeleted }
            .map { DocumentListCellViewModel(document: $0, isShared: true) }

        let allDocumentViewModels = ownDocumentViewModels + sharedDocumentViewModels
        documents = allDocumentViewModels.sorted(by: { $0.name < $1.name })
        return documents
    }

    func importDocument(selectedFileUrl: URL, completion: @escaping (Document?) -> Void) {
        let doesFileExist = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first != nil
        guard doesFileExist else {
            return
        }

        guard let ownerId = AuthViewModel().currentUser?.id else {
            return
        }

        Task {
            let document = Document(name: selectedFileUrl.lastPathComponent, ownerId: ownerId)
            pdfStorageManager.uploadPdf(
                fileSystemUrl: selectedFileUrl, fileName: document.id.uuidString
            )

            let createdDocument = await documentsPersistenceManager.createDocument(document: document)

            completion(createdDocument)
        }
    }

    func deleteDocumentForEveryone(viewModel: DocumentListCellViewModel) {
        Task {
            _ = await documentsPersistenceManager.deleteDocument(document: viewModel.document)
            hasDeletedDocument = true
        }
    }

    func deleteDocumentAsNonOwner(viewModel: DocumentListCellViewModel) {
        guard let recipientId = AuthViewModel().currentUser?.id else {
            return
        }

        Task {
            _ = await documentSharesPersistenceManager.deleteDocumentShare(
                document: viewModel.document, recipientId: recipientId)
            hasDeletedDocument = true
        }
    }
}

extension DocumentListViewModel {
    private func setUpSubscribers() {
        documentsPersistenceManager.$deletedDocument.sink(receiveValue: { [weak self] _ in
            self?.hasDeletedDocument = true
        }).store(in: &cancellables)
    }
}
