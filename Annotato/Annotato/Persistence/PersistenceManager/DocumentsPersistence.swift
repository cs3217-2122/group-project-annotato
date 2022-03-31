import Foundation
import AnnotatoSharedLibrary

protocol DocumentsPersistence {
    func getOwnDocuments(userId: String) async -> [Document]?
    func getSharedDocuments(userId: String) async -> [Document]?
    func getDocument(documentId: UUID) async -> Document?
    func createDocument(document: Document) async -> Document?
    func updateDocument(document: Document) async -> Document?
    func deleteDocument(document: Document) async -> Document?
}