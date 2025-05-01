import Foundation
import HealthKit
import SwiftData

/// HealthKit の睡眠分析データを SwiftData の SleepEpisode に同期するマネージャー
actor SleepEpisodeManager {
    static let shared = SleepEpisodeManager()
    private let healthStore = HKHealthStore()

    /// HealthKit の権限をリクエストします。
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "HealthKitUnavailable", code: -1)
        }
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: nil, read: [sleepType]) { success, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else if !success {
                    cont.resume(throwing: NSError(domain: "HealthKitAuthorizationDenied", code: -1))
                } else {
                    cont.resume(returning: ())
                }
            }
        }
    }

    /// 指定期間の睡眠サンプルを取得します。
    private func fetchSleepSamples(from start: Date, to end: Date) async throws -> [HKCategorySample] {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[HKCategorySample], Error>) in
            let sampleType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(sampleType: sampleType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [sort]) { _, results, error in
                if let error = error {
                    cont.resume(throwing: error)
                    return
                }
                let samples = results as? [HKCategorySample] ?? []
                cont.resume(returning: samples)
            }
            healthStore.execute(query)
        }
    }

    /// HealthKit の睡眠サンプルを SwiftData に保存します。
    /// - Parameters:
    ///   - start: 取得開始日時
    ///   - end: 取得終了日時
    ///   - context: SwiftData の ModelContext
    @MainActor
    func syncEpisodes(from start: Date, to end: Date, in context: ModelContext) async throws {
        // 権限確認
        try await requestAuthorization()
        // サンプル取得
        let samples = try await fetchSleepSamples(from: start, to: end)
        // SwiftData に保存
        for sample in samples {
            let durationMin = Int(sample.endDate.timeIntervalSince(sample.startDate) / 60)
            let episode = SleepEpisode(
                id: sample.uuid,
                startAt: sample.startDate,
                endAt: sample.endDate,
                durationMin: durationMin
            )
            context.insert(episode)
        }
        // 自動保存される
    }
} 