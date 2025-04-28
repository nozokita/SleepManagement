import SwiftUI
import HealthKit

@MainActor
final class SleepViewModel: ObservableObject {
    @Published var score: Double = .nan
    @Published var latestMetrics: SleepMetrics?

    // Dependencies injected from the shared instances
    private let metricsCalc: SleepMetricsCalculator
    private let healthKitManager: HealthKitManager

    init() {
        self.healthKitManager = HealthKitManager.shared
        let queryService = SleepQueryService(store: self.healthKitManager.healthStore)
        self.metricsCalc = SleepMetricsCalculator(queryService: queryService)
    }

    func refresh() async {
        do {
            try await healthKitManager.requestAuthorization()
            // 実際の権限ステータスを確認
            let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
            let currentStatus = healthKitManager.healthStore.authorizationStatus(for: sleepType)

            if currentStatus == .sharingAuthorized {
                let metrics = try await metricsCalc.weeklyMetrics()
                latestMetrics = metrics

                // 比較用: オリジナルのHealthKitスコアとCompositeスコアを両方計算
                let originalScore = SleepManager.shared.calculateHealthKitSleepScore(
                    durationH: metrics.durationH,
                    efficiency: metrics.efficiency,
                    regularity: metrics.regularity,
                    latency: metrics.latency,
                    waso: metrics.waso
                )
                let compositeScore = compositeSleepScore(from: metrics)
                // ログ出力で比較
                print("Original Score: \(originalScore), Composite Score: \(compositeScore)")

                score = compositeScore
            } else {
                // 権限がない場合、エラー表示やUI更新など
                print("HealthKit permission not granted. Cannot refresh data.")
                // 必要であれば、UIに状態を反映させるプロパティを追加
            }
        } catch {
            print("HealthKit refresh error: \(error)")
            // エラーハンドリング: UIにエラーメッセージを表示するなど
        }
    }
} 
