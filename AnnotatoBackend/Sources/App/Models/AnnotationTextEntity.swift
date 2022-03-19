import FluentKit
import AnnotatoSharedLibrary

final class AnnotationTextEntity: Model {
    static let schema = "annotation_text"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "type")
    var type: Int

    @Field(key: "content")
    var content: String

    @Field(key: "height")
    var height: Double

    @Parent(key: "annotation_id")
    var annotation: AnnotationEntity

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(
        type: AnnotationType,
        content: String,
        height: Double,
        annotationId: AnnotationEntity.IDValue,
        id: UUID? = nil
    ) {
        self.id = id
        self.type = type.rawValue
        self.content = content
        self.height = height
        self.$annotation.id = annotationId
    }
}

extension AnnotationTextEntity: PersistedEntity {
    static func fromModel(_ model: AnnotationText) -> Self {
        Self(
            type: model.type,
            content: model.content,
            height: model.height,
            annotationId: model.annotationId,
            id: model.id
        )
    }
}