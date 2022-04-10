import Foundation
import Combine
import AnnotatoSharedLibrary

class RootPersistenceManager: ObservableObject {
    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var crudDocumentMessage: Data?
    @Published private(set) var crudAnnotationMessage: Data?

    init() {
        setUpSubscribers()
    }

    private func setUpSubscribers() {
        WebSocketManager.shared.$message.sink { [weak self] message in
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

        publishMessage(decodedMessage: decodedMessage, message: message)
    }

    private func decodeData(data: Data) -> AnnotatoMessage? {
        do {
            let decodedMessage = try JSONCustomDecoder().decode(AnnotatoMessage.self, from: data)
            return decodedMessage
        } catch {
            AnnotatoLogger.error(
                "When decoding data. \(error.localizedDescription).",
                context: "RootPersistenceManager::decodeData"
            )
            return nil
        }
    }

    private func publishMessage(decodedMessage: AnnotatoMessage, message: Data) {
        resetPublishedAttributes()

        switch decodedMessage.type {
        case .crudDocument:
            self.crudDocumentMessage = message
        case .crudAnnotation:
            self.crudAnnotationMessage = message
        }
    }

    private func resetPublishedAttributes() {
        crudDocumentMessage = nil
        crudAnnotationMessage = nil
    }
}
