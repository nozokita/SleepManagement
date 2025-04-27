import HealthKit

final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        [HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]
    }

    @Published var authorizationStatus: HKAuthorizationRequestStatus = .unknown

    private init() {}

    @MainActor
    func requestAuthorization() async throws {
        try await store.requestAuthorization(toShare: [], read: readTypes)
        authorizationStatus = try await store.getRequestStatusForAuthorization(toShare: [], read: readTypes)
    }

    var healthStore: HKHealthStore {
        store
    }
} 