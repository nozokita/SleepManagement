import Foundation
import HealthKit

final class HealthKitManager: ObservableObject, @unchecked Sendable {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        [HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]
    }

    @Published var authorizationStatus: HKAuthorizationRequestStatus = .unknown

    private init() {
        startObserver()
    }

    @MainActor
    func requestAuthorization() async throws {
        // 読み取りのみ、書き込み権限なし
        let shareTypes: Set<HKSampleType> = []
        try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
        // 認可リクエストのステータスをコールバックで取得
        store.getRequestStatusForAuthorization(toShare: shareTypes, read: readTypes) { status, error in
            DispatchQueue.main.async {
                self.authorizationStatus = status
            }
        }
    }

    var healthStore: HKHealthStore {
        store
    }

    /// HKObserverQueryで睡眠データ変更を監視し、更新通知を発行
    private func startObserver() {
        let sampleType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { _, completionHandler, error in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .healthKitDataUpdated, object: nil)
                }
            }
            completionHandler()
        }
        store.execute(query)
        // バックグラウンド配信を有効化 (即時頻度)
        store.enableBackgroundDelivery(for: sampleType, frequency: .immediate, withCompletion: { success, error in
            if !success {
                print("Background delivery failed: \(String(describing: error))")
            }
        })
    }
}

// 通知名定義を追加
extension Notification.Name {
    static let healthKitDataUpdated = Notification.Name("HealthKitDataUpdated")
} 