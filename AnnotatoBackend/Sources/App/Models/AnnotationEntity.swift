import Foundation
import FluentKit
import AnnotatoSharedLibrary

final class AnnotationEntity: Model {
    static let schema = "annotations"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "origin_x")
    var originX: Double

    @Field(key: "origin_y")
    var originY: Double

    @Field(key: "width")
    var width: Double

    @Field(key: "owner_id")
    var ownerId: String

    @Parent(key: "document_id")
    var documentEntity: DocumentEntity

    @Children(for: \.$annotationEntity)
    var annotationTextEntities: [AnnotationTextEntity]

    @Children(for: \.$annotationEntity)
    var annotationHandwritingEntities: [AnnotationHandwritingEntity]

    @OptionalChild(for: \.$annotationEntity)
    var selectionBox: SelectionBoxEntity?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    var isDeleted: Bool {
        deletedAt != nil
    }

    init() { }

    init(
        originX: Double,
        originY: Double,
        width: Double,
        ownerId: String,
        documentId: DocumentEntity.IDValue,
        id: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.originX = originX
        self.originY = originY
        self.width = width
        self.ownerId = ownerId
        self.$documentEntity.id = documentId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

extension AnnotationEntity: PersistedEntity {
    static func fromModel(_ model: Annotation) -> Self {
        Self(
            originX: model.origin.x,
            originY: model.origin.y,
            width: model.width,
            ownerId: model.ownerId,
            documentId: model.documentId,
            id: model.id,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt,
            deletedAt: model.deletedAt
        )
    }
}
