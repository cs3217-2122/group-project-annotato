import Foundation
import AnnotatoSharedLibrary

class OfflineToOnlineWebSocketManager {
    @Published private(set) var isResolvingChanges = false
    private let storageService: AnnotatoStorageService

    init() {
        self.storageService = FirebaseStorage()
    }

    func handleResponseData(data: Data) {
        do {
            AnnotatoLogger.info("Handling offline to online response data...")
            let message = try JSONCustomDecoder().decode(AnnotatoOfflineToOnlineMessage.self, from: data)
            AnnotatoLogger.info("Last online time was \(message.lastOnlineAt)...")

            Task {
                switch message.mergeStrategy {
                case .keepServerVersion:
                    await handleKeepServerResponse(message: message)
                case .overrideServerVersion:
                    await handleOverrideServerResponse(message: message)
                }

                isResolvingChanges = false
            }
        } catch {
            AnnotatoLogger.error("When handling response data. \(error.localizedDescription)",
                                 context: "OfflineToOnlineWebSocketManager::handleResponseData")
        }
    }

    private func handleKeepServerResponse(message: AnnotatoOfflineToOnlineMessage) async {
        let lastOnlineAt = message.lastOnlineAt

        let newLocalDocumentsWhileOffline = LocalPersistenceManager.shared
            .fetchDocumentsCreatedAfterDate(date: lastOnlineAt) ?? []

        for document in newLocalDocumentsWhileOffline {
            _ = await LocalPersistenceManager.shared.documents
                .deleteDocument(document: document)
        }

        let newLocalAnnotationsWhileOffline = LocalPersistenceManager.shared
            .fetchAnnotationsCreatedAfterDate(date: lastOnlineAt) ?? []

        for annotation in newLocalAnnotationsWhileOffline {
            _ = await LocalPersistenceManager.shared.annotations
                .deleteAnnotation(annotation: annotation)
        }

        await createOrUpdateEntities(message: message)
    }

    private func handleOverrideServerResponse(message: AnnotatoOfflineToOnlineMessage) async {
        await createOrUpdateEntities(message: message)
    }

    private func createOrUpdateEntities(message: AnnotatoOfflineToOnlineMessage) async {
        let documents = message.documents
        let annotations = message.annotations

        _ = await LocalPersistenceManager.shared.documents
            .createOrUpdateDocuments(documents: documents)
        _ = await LocalPersistenceManager.shared.annotations
            .createOrUpdateAnnotations(annotations: annotations)
    }

    func sendOnlineMessage(mergeStrategy: AnnotatoOfflineToOnlineMergeStrategy) {
        guard let lastOnlineDatetime = NetworkMonitor.shared.getLastOnlineDatetime() else {
            isResolvingChanges = false
            return
        }

        isResolvingChanges = true

        let documents = LocalPersistenceManager.shared
            .fetchDocumentsUpdatedAfterDate(date: lastOnlineDatetime) ?? []

        for document in documents where document.baseFileUrl == nil {
            storageService.uploadPdf(fileSystemUrl: document.localFileUrl, withId: document.id)
        }

        let annotations = LocalPersistenceManager.shared
            .fetchAnnotationsUpdatedAfterDate(date: lastOnlineDatetime) ?? []

        guard let senderId = AnnotatoAuth().currentUser?.uid else {
            return
        }

        let message = AnnotatoOfflineToOnlineMessage(senderId: senderId,
                                                     mergeStrategy: mergeStrategy,
                                                     lastOnlineAt: lastOnlineDatetime,
                                                     documents: documents, annotations: annotations)

        WebSocketManager.shared.send(message: message)
    }
}
