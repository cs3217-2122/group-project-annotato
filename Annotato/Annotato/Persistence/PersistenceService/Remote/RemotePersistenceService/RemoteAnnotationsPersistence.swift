import AnnotatoSharedLibrary

struct RemoteAnnotationsPersistence: AnnotationsRemotePersistence {
    private let webSocketManager: WebSocketManager?

    init(webSocketManager: WebSocketManager?) {
        self.webSocketManager = webSocketManager
    }

    func createAnnotation(annotation: Annotation) async -> Annotation? {
        guard let senderId = AuthViewModel().currentUser?.id else {
            return nil
        }

        let webSocketMessage = AnnotatoCudAnnotationMessage(
            senderId: senderId, subtype: .createAnnotation, annotation: annotation
        )

        webSocketManager?.send(message: webSocketMessage)

        // We do not get any response for the sender from the websocket
        return nil
    }

    func updateAnnotation(annotation: Annotation) async -> Annotation? {
        guard let senderId = AuthViewModel().currentUser?.id else {
            return nil
        }

        let webSocketMessage = AnnotatoCudAnnotationMessage(
            senderId: senderId, subtype: .updateAnnotation, annotation: annotation
        )

        webSocketManager?.send(message: webSocketMessage)

        // We do not get any response for the sender from the websocket
        return nil
    }

    func deleteAnnotation(annotation: Annotation) async -> Annotation? {
        guard let senderId = AuthViewModel().currentUser?.id else {
            return nil
        }

        let webSocketMessage = AnnotatoCudAnnotationMessage(
            senderId: senderId, subtype: .deleteAnnotation, annotation: annotation
        )

        webSocketManager?.send(message: webSocketMessage)

        // We do not get any response for the sender from the websocket
        return nil
    }

    func createOrUpdateAnnotation(annotation: Annotation) -> Annotation? {
        fatalError("RemoteAnnotationsPersistence::createOrUpdateAnnotation: This function should not be called")
        return nil
    }

    func createOrUpdateAnnotations(annotations: [Annotation]) -> [Annotation]? {
        fatalError("RemoteAnnotationsPersistence::createOrUpdateAnnotations: This function should not be called")
        return nil
    }
}
