import CoreGraphics
import Foundation

class SampleData {
    func exampleDocumentsInList() -> [DocumentListViewModel] {
        [
            DocumentListViewModel(name: "Lab01 Qns", baseFileUrl: exampleUrlLab01Qns()),
            DocumentListViewModel(name: "L0 Overview", baseFileUrl: exampleUrlL0Overview()),
            DocumentListViewModel(name: "L1 Intro", baseFileUrl: exampleUrlL1Intro()),
            DocumentListViewModel(name: "Firebase Clean Code", baseFileUrl: exampleUrlFirebase()),
            DocumentListViewModel(name: "Test E", baseFileUrl: exampleUrlL0Overview())
        ]
    }

    func exampleDocument() -> DocumentViewModel {
        DocumentViewModel(
            annotations: SampleData().exampleAnnotations(),
            pdfDocument: SampleData().examplePdfDocument())
    }

    func exampleAnnotations() -> [DocumentAnnotationViewModel] {
        [
            DocumentAnnotationViewModel(
                center: CGPoint(x: 450.0, y: 150.0),
                width: 300.0,
                parts: exampleAnnotationParts1()
            ),
            DocumentAnnotationViewModel(
                center: CGPoint(x: 600.0, y: 300.0),
                width: 250.0,
                parts: exampleAnnotationParts2())
        ]
    }

    private func examplePdfDocument() -> DocumentPdfViewModel {
        DocumentPdfViewModel(baseFileUrl: SampleData().exampleUrlLab01Qns())
    }

    private func exampleUrlLab01Qns() -> URL {
        guard let baseFileUrl = Bundle.main.url(forResource: "Lab01Qns", withExtension: "pdf") else {
            fatalError("example baseFileUrl not valid")
        }
        return baseFileUrl
    }

    private func exampleUrlL0Overview() -> URL {
        guard let baseFileUrl = Bundle.main.url(
            forResource: "L0 - Course Overview",
            withExtension: "pdf"
        ) else {
            fatalError("example baseFileUrl not valid")
        }
        return baseFileUrl
    }

    private func exampleUrlL1Intro() -> URL {
        guard let baseFileUrl = Bundle.main.url(forResource: "L1 - Introduction", withExtension: "pdf") else {
            fatalError("example baseFileUrl not valid")
        }
        return baseFileUrl
    }

    private func exampleUrlFirebase() -> URL {
        let firebaseUrlString = "https://firebasestorage.googleapis.com" +
            ":443/v0/b/annotato" + "-ba051.appspot.com/o/clean-cod" +
            "e.pdf?alt=media&token=513532aa-9c96-42ce-9a62-b4a49a8ec37c"
        let firebaseUrl = URL(string: firebaseUrlString)
        guard let firebaseUrl = firebaseUrl else {
            fatalError("firebase url not valid")
        }

        return firebaseUrl
    }

    private func exampleAnnotationParts1() -> [DocumentAnnotationPartViewModel] {
        [
            DocumentAnnotationTextViewModel(content: "I am hungry", height: 30.0),
            DocumentAnnotationTextViewModel(content: "ABC\nDEF", height: 60.0)
        ]
    }

    private func exampleAnnotationParts2() -> [DocumentAnnotationPartViewModel] {
        [
            DocumentAnnotationTextViewModel(
                content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                height: 44.0),
            DocumentAnnotationTextViewModel(content: "Hello\nHello\nHello", height: 60.0)
        ]
    }
}
