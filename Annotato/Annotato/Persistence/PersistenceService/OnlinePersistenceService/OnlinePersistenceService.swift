import AnnotatoSharedLibrary
import Foundation

struct OnlinePersistenceService: PersistenceService {
    let remotePersistence: PersistenceManager
    let localPersistence: PersistenceManager

    init(remotePersistence: PersistenceManager, localPersistence: PersistenceManager) {
        self.remotePersistence = remotePersistence
        self.localPersistence = localPersistence
    }
}
