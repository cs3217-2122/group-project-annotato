import Vapor
import Fluent
import AnnotatoSharedLibrary

func routes(_ app: Application) throws {
    app.get { _ in
        "AnnotatoBackend up and running!"
    }

    app.group("documents", configure: documentsRouter)
}