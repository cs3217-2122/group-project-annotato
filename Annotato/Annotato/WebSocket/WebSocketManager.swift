import Foundation
import AnnotatoSharedLibrary

class WebSocketManager {
    static let shared = WebSocketManager()

    private(set) var socket: URLSessionWebSocketTask?
    let documentManager = DocumentWebSocketManager()
    let annotationManager = AnnotationWebSocketManager()

    private init() { }

    func setSocket(to webSocketSession: URLSessionWebSocketTask) {
        guard let userId = AnnotatoAuth().currentUser?.uid else {
            AnnotatoLogger.error("Unable to retrieve user id.", context: "WebSocketManager::init")
            return
        }

        guard let url = URL(string: "\(BaseAPI.baseWsAPIUrl)/ws/\(userId)") else {
            return
        }

        socket = URLSession(configuration: .default).webSocketTask(with: url)
        listen()
        socket?.resume()
    }

    func resetSocket() {
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
    }

    func listen() {
        socket?.receive { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .failure(let error):
                AnnotatoLogger.error(error.localizedDescription)
            case .success(let message):
                switch message {
                case .data(let data):
                    self.handleResponseData(data: data)
                case .string(let str):
                    guard let data = str.data(using: .utf8) else {
                        return
                    }

                    self.handleResponseData(data: data)
                @unknown default:
                    break
                }
            }

            // We need to re-register the callback closure after a message is received
            self.listen()
        }
    }

    func send<T: Codable>(message: T) {
        do {

            let data = try JSONEncoder().encode(message)
            socket?.send(.data(data)) { error in
                if let error = error {
                    AnnotatoLogger.error(
                        "While sending data. \(error.localizedDescription).",
                        context: "WebSocketManager:send:"
                    )
                }
            }

        } catch {
            AnnotatoLogger.error(
                "When sending data. \(error.localizedDescription).",
                context: "WebSocketManager:send:"
            )
        }
    }

    private func handleResponseData(data: Data) {
        do {

            let message = try JSONDecoder().decode(AnnotatoMessage.self, from: data)

            switch message.type {
            case .crudDocument:
                documentManager.handleResponseData(data: data)
            case .crudAnnotation:
                annotationManager.handleResponseData(data: data)
            case .offlineToOnline:
                print("Not implemented yet. Do nothing.")
            }

        } catch {
            AnnotatoLogger.error(
                "When handling reponse data. \(error.localizedDescription).",
                context: "WebSocketManager:handleResponseData:"
            )
        }
    }
}
