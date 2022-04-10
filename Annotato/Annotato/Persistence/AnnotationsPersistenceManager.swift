import AnnotatoSharedLibrary
import Foundation
import Combine

class AnnotationsPersistenceManager: AnnotationsPersistence {
    private let rootPersistenceManager = RootPersistenceManager()

    private let remotePersistence = RemotePersistenceService()
    private let localPersistence = LocalPersistenceService.shared
    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var newAnnotation: Annotation?
    @Published private(set) var updatedAnnotation: Annotation?
    @Published private(set) var deletedAnnotation: Annotation?

    init() {
        setUpSubscribers()
    }

    func createAnnotation(annotation: Annotation) async -> Annotation? {
        _ = await remotePersistence.annotations.createAnnotation(annotation: annotation)

        annotation.setCreatedAt()
        return await localPersistence.annotations.createAnnotation(annotation: annotation)
    }

    func updateAnnotation(annotation: Annotation) async -> Annotation? {
        _ = await remotePersistence.annotations.updateAnnotation(annotation: annotation)

        annotation.setUpdatedAt()
        return await localPersistence.annotations.updateAnnotation(annotation: annotation)
    }

    func deleteAnnotation(annotation: Annotation) async -> Annotation? {
        _ = await remotePersistence.annotations.deleteAnnotation(annotation: annotation)

        annotation.setDeletedAt()
        return await localPersistence.annotations.deleteAnnotation(annotation: annotation)
    }

    func createOrUpdateAnnotation(annotation: Annotation) -> Annotation? {
        fatalError("PersistenceManager::createOrUpdateAnnotation: This function should not be called")
        return nil
    }

    func createOrUpdateAnnotations(annotations: [Annotation]) -> [Annotation]? {
        fatalError("PersistenceManager::createOrUpdateAnnotations: This function should not be called")
        return nil
    }
}

// MARK: Websocket
extension AnnotationsPersistenceManager {
    private func setUpSubscribers() {
        rootPersistenceManager.$crudAnnotationMessage.sink { [weak self] message in
            guard let message = message else {
                return
            }

            self?.handleIncomingMessage(message: message)
        }.store(in: &cancellables)
    }

    private func handleIncomingMessage(message: Data) {
        guard let decodedMessage = decodeData(data: message) else {
            return
        }

        let annotation = decodedMessage.annotation
        let senderId = decodedMessage.senderId

        Task {
            _ = await localPersistence.annotations
                .createOrUpdateAnnotation(annotation: annotation)
        }

        guard senderId != AnnotatoAuth().currentUser?.uid else {
            return
        }

        publishAnnotation(decodedMessage: decodedMessage, annotation: annotation)
    }

    private func decodeData(data: Data) -> AnnotatoCudAnnotationMessage? {
        do {
            let decodedMessage = try JSONCustomDecoder().decode(AnnotatoCudAnnotationMessage.self, from: data)
            return decodedMessage
        } catch {
            AnnotatoLogger.error(
                "When decoding data. \(error.localizedDescription).",
                context: "AnnotationsPersistenceManager::decodeData"
            )
            return nil
        }
    }

    private func publishAnnotation(decodedMessage: AnnotatoCudAnnotationMessage, annotation: Annotation) {
        resetPublishedAttributes()

        switch decodedMessage.subtype {
        case .createAnnotation:
            newAnnotation = annotation
            AnnotatoLogger.info("Annotation was created. \(annotation)")
        case .updateAnnotation:
            updatedAnnotation = annotation
            AnnotatoLogger.info("Annotation was updated. \(annotation)")
        case .deleteAnnotation:
            deletedAnnotation = annotation
            AnnotatoLogger.info("Annotation was deleted. \(annotation)")
        }
    }

    private func resetPublishedAttributes() {
        newAnnotation = nil
        updatedAnnotation = nil
        deletedAnnotation = nil
    }
}
