import AnnotatoSharedLibrary

extension AnnotationHandwritingEntity {
    func customUpdate(usingUpdatedModel annotationHandwriting: AnnotationHandwriting) {
        self.copyPropertiesOf(updatedModel: annotationHandwriting)
    }

    private func copyPropertiesOf(updatedModel annotationHandwriting: AnnotationHandwriting) {
        precondition(id == annotationHandwriting.id)

        handwriting = annotationHandwriting.handwriting
        height = annotationHandwriting.height
        order = Int64(annotationHandwriting.order)

        if let annotationEntity = LocalAnnotationEntityDataAccess
            .read(annotationId: annotationHandwriting.annotationId) {
            self.annotationEntity = annotationEntity
        }

        createdAt = annotationHandwriting.createdAt
        updatedAt = annotationHandwriting.updatedAt
        deletedAt = annotationHandwriting.deletedAt
    }
}
