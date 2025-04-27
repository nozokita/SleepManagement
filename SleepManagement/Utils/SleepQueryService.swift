import Foundation
import HealthKit

// SleepCategoryサンプルを扱いやすくラップするモデル
struct SleepSegment: Identifiable {
    let id: UUID
    let state: HKCategoryValueSleepAnalysis
    let start: Date
    let end: Date
    var duration: TimeInterval { end.timeIntervalSince(start) }
}

actor SleepQueryService {
    private let store: HKHealthStore
    private let calendar = Calendar.current

    init(store: HKHealthStore) {
        self.store = store
    }

    /// 指定日の 0:00 〜 翌日0:00 の睡眠セグメントを取得
    func fetchSegments(for date: Date) async throws -> [SleepSegment] {
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: dayEnd, options: .strictStartDate)
        let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!

        return try await withCheckedThrowingContinuation { cont in
            let query = HKSampleQuery(sampleType: type,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    cont.resume(throwing: error)
                    return
                }
                let segments = (samples as? [HKCategorySample])?.map {
                    SleepSegment(id: $0.uuid,
                                 state: HKCategoryValueSleepAnalysis(rawValue: $0.value)!,
                                 start: $0.startDate,
                                 end: $0.endDate)
                } ?? []
                cont.resume(returning: segments)
            }
            store.execute(query)
        }
    }
} 