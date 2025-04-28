import Foundation
import HealthKit

final class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    private init() {}

    /// HealthKitの権限をリクエストします。
    /// - Parameter completion: 成功時はtrue、失敗時はfalseとエラー情報を返します。
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // HealthKitが利用可能かチェック
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }
        // 読み取り権限をリクエストするデータタイプ（睡眠分析）
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let typesToRead: Set<HKObjectType> = [sleepType]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    /// 指定期間の睡眠分析データをフェッチします。
    /// - Parameters:
    ///   - startDate: 取得開始日時
    ///   - endDate: 取得終了日時
    ///   - completion: 成功時にHKCategorySampleの配列、失敗時にエラーを返します。
    func fetchSleepAnalysis(startDate: Date, endDate: Date, completion: @escaping ([HKCategorySample]?, Error?) -> Void) {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: sleepType,
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: [sortDescriptor]) { _, samplesOrNil, error in
            DispatchQueue.main.async {
                guard let samples = samplesOrNil as? [HKCategorySample] else {
                    completion(nil, error)
                    return
                }
                completion(samples, nil)
            }
        }
        healthStore.execute(query)
    }
}

// ※ Info.plistに"Privacy - Health Share Usage Description"の記載をお忘れなく。 