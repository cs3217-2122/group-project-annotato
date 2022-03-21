import Foundation

public final class AnnotationText: Codable {
    public let id: UUID
    public let type: AnnotationType
    public private(set) var content: String
    public private(set) var height: Double
    public private(set) var order: Int
    public let annotationId: UUID

    public required init(
        type: AnnotationType,
        content: String,
        height: Double,
        order: Int,
        annotationId: UUID,
        id: UUID? = nil
    ) {
        self.id = id ?? UUID()
        self.type = type
        self.content = content
        self.height = height
        self.order = order
        self.annotationId = annotationId
    }
}

extension AnnotationText: CustomDebugStringConvertible {
    public var debugDescription: String {
        "AnnotationText(id: \(id), type: \(type), content: \(content), " +
        "height: \(height), order: \(order), annotationId: \(annotationId))"
    }
}
