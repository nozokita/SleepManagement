import Foundation
import CoreData
import UserNotifications
import HealthKit

class SleepManager: ObservableObject {
    static let shared = SleepManager()
    
    /// HealthKit用のストア
    private let healthStore = HKHealthStore()
    
    // 推奨睡眠時間（デフォルト7時間）
    var recommendedSleepHours: Double = 7.0
    
    // スライディングウィンドウの日数
    let debtWindowDays = 10
    
    // 睡眠スコアの計算 (手動入力用)
    func calculateSleepScore(startAt: Date, endAt: Date, quality: Int16) -> Double {
        let durationH = endAt.timeIntervalSince(startAt) / 3600
        let timeRatio = min(durationH / recommendedSleepHours, 1.0)
        let subjectiveRatio = Double(quality) / 5.0
        return 60.0 * timeRatio + 40.0 * subjectiveRatio
    }
    
    /// HealthKit連携時に用いる多要素モデルでの睡眠スコア計算 (100点満点)
    func calculateHealthKitSleepScore(durationH: Double,
                                      efficiency: Double,
                                      regularity: Double,
                                      latency: Double,
                                      waso: Double) -> Double {
        let durScore = 40.0 * min(durationH / recommendedSleepHours, 1.0)
        let effScore = 25.0 * min(efficiency / 0.85, 1.0)
        let regScore = 15.0 * (1.0 - regularity / 100.0)
        let latScore = 10.0 * max(0.0, (30.0 - latency) / 30.0)
        let wasoScore = 10.0 * max(0.0, (30.0 - waso) / 30.0)
        return durScore + effScore + regScore + latScore + wasoScore
    }
    
    /// 年齢別推奨睡眠時間 (NSF/AASM 2015)
    func guidelineHours(age: Int) -> Double {
        switch age {
        case 14..<18: return 9.0
        case 18..<65: return 8.0
        case 65...:   return 7.5
        default:       return recommendedSleepHours
        }
    }
    
    // 日次睡眠負債の計算
    func calculateDailyDebt(sleepHours: Double) -> Double {
        // ① ユーザー設定から取得した理想睡眠時間（秒）→時間に変換
        let idealHours = SettingsManager.shared.idealSleepDuration / 3600
        // ② （Placeholder）年齢別ガイドラインは guidelineHours で定義済み
        // let age = Calendar.current.component(.year, from: Date()) - SettingsManager.shared.birthYear
        // let placeholderIdeal = guidelineHours(age: age)
        return max(idealHours - sleepHours, 0)
    }
    
    // MARK: - 重み付け関数 (質×時間)
    /// ナップ時間（分）に応じた回復係数を返す
    func weight(for minutes: Int) -> Double {
        switch minutes {
        case ..<10: return 0.0
        case ..<30: return 0.3
        case ..<60: return 0.6
        case ..<90: return 0.9
        default:    return 1.0
        }
    }
    
    // MARK: - 急性睡眠負債 (ローリング24h) の計算
    /// 過去24時間分の睡眠エピソードを重み付きで合計し、理想睡眠時間との差を返す
    func calculateAcuteDebt(context: NSManagedObjectContext) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let since = calendar.date(byAdding: .hour, value: -24, to: now)!
        // 24h以内に終了した記録を取得
        let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
        request.predicate = NSPredicate(format: "endAt >= %@", since as NSDate)
        do {
            let records = try context.fetch(request)
            // 重み付き合計 (時間)
            let effectiveHours = records.reduce(0.0) { sum, record in
                guard let start = record.startAt, let end = record.endAt else { return sum }
                let durationMin = Int(end.timeIntervalSince(start) / 60)
                return sum + weight(for: durationMin) * (Double(durationMin) / 60)
            }
            let idealHours = SettingsManager.shared.idealSleepDuration / 3600
            return max(idealHours - effectiveHours, 0)
        } catch {
            print("急性睡眠負債の計算に失敗: \(error)")
            return 0
        }
    }
    
    /// 基準時刻（正午±6hシフト可）を返す
    func anchor(for date: Date, context: NSManagedObjectContext) -> Date {
        let calendar = Calendar.current
        guard let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) else { return date }
        // 過去24hの睡眠記録から最長エピソードの中央時刻を取得
        let since = calendar.date(byAdding: .hour, value: -24, to: noon)!
        let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
        request.predicate = NSPredicate(format: "startAt >= %@ AND endAt <= %@", since as NSDate, noon as NSDate)
        do {
            let records = try context.fetch(request)
            if let longest = records.max(by: { ($0.endAt!.timeIntervalSince($0.startAt!)) < ($1.endAt!.timeIntervalSince($1.startAt!)) }), let start = longest.startAt, let end = longest.endAt {
                let midpoint = start.addingTimeInterval(end.timeIntervalSince(start)/2)
                let diff = midpoint.timeIntervalSince(noon)
                if diff > 6*3600 {
                    return calendar.date(byAdding: .hour, value: 6, to: noon)!
                } else if diff < -6*3600 {
                    return calendar.date(byAdding: .hour, value: -6, to: noon)!
                }
            }
        } catch {
            print("アンカー算出失敗: \(error)")
        }
        return noon
    }

    // 過去N日間の睡眠負債をアンカー付き24hウインドウで計算
    func calculateTotalDebt(context: NSManagedObjectContext, days: Int = 7) -> Double {
        let calendar = Calendar.current
        var totalDebt: Double = 0
        for dayOffset in 0..<days {
            // 基準日（offset日前）のアンカーを計算
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let windowStart = anchor(for: date, context: context)
            let windowEnd = calendar.date(byAdding: .hour, value: 24, to: windowStart)!
            // ウインドウ内のエピソードを取得
            let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
            request.predicate = NSPredicate(format: "startAt < %@ AND endAt > %@", windowEnd as NSDate, windowStart as NSDate)
            do {
                let records = try context.fetch(request)
                // 合計睡眠時間（時間単位）
                let dailySleepHours = records.reduce(0.0) { sum, record in
                    guard let start = record.startAt, let end = record.endAt else { return sum }
                    return sum + end.timeIntervalSince(start) / 3600
                }
                let dailyDebt = calculateDailyDebt(sleepHours: dailySleepHours)
                totalDebt += dailyDebt
            } catch {
                print("睡眠負債の計算に失敗しました (offset:\(dayOffset)): \(error)")
            }
        }
        return totalDebt
    }
    
    // 仮眠が必要かどうかの判断
    func needsNap(debt: Double) -> Bool {
        // 睡眠負債が5.25時間（推奨睡眠時間の75%）を超えたら仮眠を推奨
        return debt > (recommendedSleepHours * 0.75)
    }
    
    // ローカル通知のスケジュール
    func scheduleNapNotification() {
        let content = UNMutableNotificationContent()
        content.title = "睡眠負債が蓄積されています"
        content.body = "健康を維持するために20〜30分の仮眠をおすすめします。"
        content.sound = UNNotificationSound.default
        
        // 現在の時間から1時間後に通知
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let request = UNNotificationRequest(identifier: "napReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("仮眠通知のスケジュールに失敗しました: \(error)")
            }
        }
    }
    
    func scheduleSleepReminder(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "就寝時間です"
        content.body = "質の良い睡眠のために、そろそろ就寝準備を始めましょう。"
        content.sound = UNNotificationSound.default
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: time)
        components.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "sleepReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("就寝通知のスケジュールに失敗しました: \(error)")
            }
        }
    }
    
    func scheduleMorningSummary(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "睡眠サマリー"
        content.body = "昨夜の睡眠状態を確認しましょう。アプリを開いて詳細をご覧ください。"
        content.sound = UNNotificationSound.default
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: time)
        components.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "morningSummary", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("朝のサマリー通知のスケジュールに失敗しました: \(error)")
            }
        }
    }
    
    /// 仮眠時に使用する、週単位 (last 7 days) の睡眠負債を計算 (Nap 減算含む)
    /// - Parameters:
    ///   - context: NSManagedObjectContext
    ///   - days: 集計日数 (デフォルト7日)
    ///   - napDuration: 仮眠時間 (秒)
    /// - Returns: 再計算後の週負債 (時間)
    func calculateWeeklyDebt(context: NSManagedObjectContext, days: Int = 7, napDuration: TimeInterval) -> Double {
        // 1) 週内の原始的な負債合計
        let rawDebt = calculateTotalDebt(context: context, days: days)
        // 2) 仮眠減算は30分(1800秒)上限
        let deduction = min(napDuration, 1800)
        return max(0, rawDebt - deduction)
    }
    
    // 新しい睡眠記録を追加
    func addSleepRecord(context: NSManagedObjectContext, startAt: Date, endAt: Date, quality: Int16, sleepType: SleepRecordType = .normalSleep, memo: String? = nil) -> SleepRecord {
        let record = SleepRecord(context: context)
        record.id = UUID()
        record.startAt = startAt
        record.endAt = endAt
        record.quality = quality
        record.memo = memo
        record.createdAt = Date()
        record.sleepType = sleepType.rawValue
        
        // 仮眠時はスコアを0、週負債を再計算
        let durationSeconds = endAt.timeIntervalSince(startAt)
        if sleepType == .nap {
            record.score = 0
            // 週単位の負債を算出 (7日間、仮眠減算)
            let weeklyDebt = self.calculateWeeklyDebt(context: context, days: 7, napDuration: durationSeconds)
            record.debt = weeklyDebt
        } else {
            // 通常記録は既存ロジック
            let durationHours = durationSeconds / 3600
            record.score = self.calculateSleepScore(startAt: startAt, endAt: endAt, quality: quality)
            record.debt = self.calculateDailyDebt(sleepHours: durationHours)
        }
        
        // 保存
        do {
            try context.save()
            
            // 睡眠負債が一定以上なら通知をスケジュール
            let totalDebt = calculateTotalDebt(context: context)
            if needsNap(debt: totalDebt) {
                scheduleNapNotification()
            }
            
            return record
        } catch {
            print("睡眠記録の保存に失敗しました: \(error)")
            context.rollback()
            
            // エラー時は空のレコードを返す
            return SleepRecord(context: context)
        }
    }
    
    // 通知許可をリクエスト
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知許可が承認されました")
            } else if let error = error {
                print("通知許可エラー: \(error)")
            }
        }
    }
    
    // MARK: - チャートデータ取得
    
    /// 過去7日間の睡眠データを取得
    func getWeeklyChartData(context: NSManagedObjectContext) -> [SleepChartData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        
        return getChartData(context: context, from: sevenDaysAgo, to: calendar.date(byAdding: .day, value: 1, to: today)!)
    }
    
    /// 過去30日間の睡眠データを取得
    func getMonthlyChartData(context: NSManagedObjectContext) -> [SleepChartData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: today)!
        
        return getChartData(context: context, from: thirtyDaysAgo, to: calendar.date(byAdding: .day, value: 1, to: today)!)
    }
    
    /// 指定期間の睡眠チャートデータを取得
    private func getChartData(context: NSManagedObjectContext, from: Date, to: Date) -> [SleepChartData] {
        let calendar = Calendar.current
        let fetchRequest: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startAt >= %@ AND startAt < %@", from as NSDate, to as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SleepRecord.startAt, ascending: true)]
        
        do {
            // 1. フェッチしたレコードを取得
            let allRecords = try context.fetch(fetchRequest)
            // 2. 不正入力（開始時刻 >= 終了時刻）とユーザー設定による仮眠扱いの記録を除外
            let records = allRecords.filter { record in
                guard let startAt = record.startAt, let endAt = record.endAt else { return false }
                // 開始時刻が終了時刻以上の場合は誤入力とみなして除外
                if endAt <= startAt {
                    return false
                }
                // ユーザー設定で短い睡眠を仮眠扱いとする場合、Nap タイプは除外
                if SettingsManager.shared.treatShortSleepAsNap,
                   record.sleepType == SleepRecordType.nap.rawValue {
                    return false
                }
                return true
            }
            
            // グループ化用の辞書
            var dailyRecords: [Date: [SleepRecord]] = [:]
            for record in records {
                guard let startAt = record.startAt else { continue }
                let dateKey = calendar.startOfDay(for: startAt)
                if dailyRecords[dateKey] == nil {
                    dailyRecords[dateKey] = []
                }
                dailyRecords[dateKey]?.append(record)
            }
            
            // 各日のデータを集計
            var chartData: [SleepChartData] = []
            
            // 日付の範囲内の各日を処理
            var currentDate = from
            while currentDate < to {
                if let dayRecords = dailyRecords[currentDate], !dayRecords.isEmpty {
                    // その日の合計睡眠時間を計算
                    let totalDuration = dayRecords.reduce(0.0) { sum, record in
                        guard let startAt = record.startAt, let endAt = record.endAt else { return sum }
                        return sum + endAt.timeIntervalSince(startAt)
                    }
                    
                    // その日の平均スコアを計算
                    let averageScore = dayRecords.reduce(0.0) { sum, record in
                        return sum + record.score
                    } / Double(dayRecords.count)
                    
                    let data = SleepChartData(
                        date: currentDate,
                        duration: totalDuration,
                        score: averageScore
                    )
                    chartData.append(data)
                } else {
                    // データがない日はゼロデータを追加
                    let data = SleepChartData(
                        date: currentDate,
                        duration: 0,
                        score: 0
                    )
                    chartData.append(data)
                }
                
                // 次の日に進む
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            return chartData
            
        } catch {
            print("チャートデータの取得に失敗しました: \(error)")
            return []
        }
    }
    
    /// 睡眠負債の推移データを取得
    func getSleepDebtTrend(context: NSManagedObjectContext, days: Int = 30) -> [Date: Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -(days-1), to: today)!
        
        let fetchRequest: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startAt >= %@", startDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SleepRecord.startAt, ascending: true)]
        
        do {
            let records = try context.fetch(fetchRequest)
            var debtTrend: [Date: Double] = [:]
            
            // 各日のベースとなる0データを設定
            var currentDate = startDate
            while currentDate <= today {
                debtTrend[currentDate] = 0.0
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            // 記録がある日の負債を計算
            for record in records {
                guard let startAt = record.startAt else { continue }
                let dateKey = calendar.startOfDay(for: startAt)
                
                if let existingDebt = debtTrend[dateKey] {
                    debtTrend[dateKey] = existingDebt + (record.debt > 0 ? record.debt : 0)
                }
            }
            
            return debtTrend
            
        } catch {
            print("睡眠負債トレンドの取得に失敗しました: \(error)")
            return [:]
        }
    }
    
    /// HealthKitから過去N日分の睡眠データを取得してCoreDataに保存します
    func syncSleepDataFromHealthKit(context: NSManagedObjectContext, days: Int = 30, completion: ((Error?) -> Void)? = nil) {
        // SleepAnalysisのサンプル取得
        let sampleType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(sampleType: sampleType,
                                 predicate: predicate,
                                 limit: HKObjectQueryNoLimit,
                                 sortDescriptors: [sortDescriptor]) { _, results, error in
            if let error = error {
                DispatchQueue.main.async { completion?(error) }
                return
            }
            guard let samples = results as? [HKCategorySample] else {
                DispatchQueue.main.async { completion?(error) }
                return
            }
            // CoreData操作をmain contextのperformで実行し、重複を回避
            context.perform {
                samples.forEach { sample in
                    let sampleId = sample.uuid
                    // 重複チェック(idで判別)
                    let fetchRequest: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", sampleId as CVarArg)
                    if (try? context.count(for: fetchRequest)) ?? 0 > 0 {
                        return
                    }
                    let record = SleepRecord(context: context)
                    record.id = sampleId
                    record.startAt = sample.startDate
                    record.endAt = sample.endDate
                    record.quality = Int16(1)
                    record.createdAt = sample.endDate
                    let durationSec = sample.endDate.timeIntervalSince(sample.startDate)
                    if SettingsManager.shared.autoSyncHealthKit {
                        if SettingsManager.shared.treatShortSleepAsNap,
                           durationSec < SettingsManager.shared.shortSleepThreshold {
                            record.sleepType = SleepRecordType.nap.rawValue
                            record.score = 0
                            record.debt = self.calculateWeeklyDebt(context: context, days: 7, napDuration: durationSec)
                        } else {
                            record.sleepType = SleepRecordType.normalSleep.rawValue
                            let durationH = durationSec / 3600
                            let efficiency = 1.0
                            let regularity = 100.0
                            let latency = 0.0
                            let waso = 0.0
                            record.score = self.calculateHealthKitSleepScore(durationH: durationH,
                                                                        efficiency: efficiency,
                                                                        regularity: regularity,
                                                                        latency: latency,
                                                                        waso: waso)
                            record.debt = self.calculateDailyDebt(sleepHours: durationH)
                        }
                    } else {
                        record.sleepType = SleepRecordType.normalSleep.rawValue
                        let durationH = durationSec / 3600
                        record.score = self.calculateSleepScore(startAt: sample.startDate, endAt: sample.endDate, quality: record.quality)
                        record.debt = self.calculateDailyDebt(sleepHours: durationH)
                    }
                }
                do {
                    try context.save()
                    DispatchQueue.main.async { completion?(nil) }
                } catch {
                    DispatchQueue.main.async { completion?(error) }
                }
            }
        }
        healthStore.execute(query)
    }
    
    /// 過去指定件数分の睡眠時間（時間単位）を取得（最新順）
    /// Fetch recent sleep durations in hours (most recent first)
    /// - Parameters:
    ///   - context: Core Data context
    ///   - limit: number of records (default 30)
    /// - Returns: array of durations in hours
    func fetchRecentSleepDurations(context: NSManagedObjectContext, limit: Int = 30) -> [Double] {
        let fetchRequest: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SleepRecord.startAt, ascending: false)]
        fetchRequest.fetchLimit = limit
        do {
            let records = try context.fetch(fetchRequest)
            return records.map { $0.durationInHours }
        } catch {
            print("睡眠時間取得に失敗しました: \(error)")
            return []
        }
    }
    
    /// 過去指定件数分の睡眠スコアを取得（最新順）
    /// Fetch recent sleep scores (most recent first)
    /// - Parameters:
    ///   - context: Core Data context
    ///   - limit: number of records (default 30)
    /// - Returns: array of scores
    func fetchRecentSleepScores(context: NSManagedObjectContext, limit: Int = 30) -> [Double] {
        let fetchRequest: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SleepRecord.startAt, ascending: false)]
        fetchRequest.fetchLimit = limit
        do {
            let records = try context.fetch(fetchRequest)
            return records.map { $0.score }
        } catch {
            print("睡眠スコア取得に失敗しました: \(error)")
            return []
        }
    }
} 