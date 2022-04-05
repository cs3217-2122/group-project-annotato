import Foundation
import AnnotatoSharedLibrary

struct AnnotatoPersistenceWrapper {
    static var currentPersistenceService: PersistenceService {
        NetworkMonitor.shared.isConnected ? onlinePersistenceService : offlinePersistenceService
    }

    private static let remotePersistence: PersistenceManager = RemotePersistenceManager()
    private static let localPersistence: PersistenceManager = LocalPersistenceManager.shared

    private static let onlinePersistenceService: PersistenceService = OnlinePersistenceService(
        remotePersistence: remotePersistence,
        localPersistence: localPersistence
    )
    private static let offlinePersistenceService: PersistenceService = OfflinePersistenceService(
        localPersistence: localPersistence
    )

    private init() { }
}