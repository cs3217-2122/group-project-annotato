import FluentKit
import AnnotatoSharedLibrary
import Foundation

struct UsersDataAccess {
    func create(db: Database, user: AnnotatoUser) async throws -> AnnotatoUser {
        let userEntity = UserEntity.fromModel(user)

        try await db.transaction { tx in
            try await userEntity.customCreate(on: tx)
        }

        return AnnotatoUser.fromManagedEntity(userEntity)
    }

    func read(db: Database, userId: String) async throws -> AnnotatoUser {
        guard let userEntity = try await UserEntity.findWithDeleted(userId, on: db).get() else {
            throw AnnotatoError.modelNotFound(
                requestType: .read,
                modelType: String(describing: AnnotatoUser.self),
                modelId: userId)
        }

        return AnnotatoUser.fromManagedEntity(userEntity)
    }

    // Note: This excludes the document owner
    func listUsersSharingDocument(db: Database, documentId: UUID) async throws -> [AnnotatoUser] {
        let userEntities = try await UserEntity
            .query(on: db)
            .join(DocumentShareEntity.self, on: \UserEntity.$id == \DocumentShareEntity.$recipientEntity.$id)
            .filter(DocumentShareEntity.self, \DocumentShareEntity.$documentEntity.$id == documentId)
            .all().get()

        return userEntities.map(AnnotatoUser.fromManagedEntity)
    }
}
