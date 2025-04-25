import Foundation
import CoreData // Import CoreData

/// 睡眠の質計算に使用するデータモデル
struct SleepQualityData {
    /// 総睡眠時間（秒）
    let totalSleepTime: Double
    /// 理想睡眠時間（秒） - 追加
    let idealSleepTime: Double
    /// ベッド内時間（秒） - 追加（睡眠効率計算に必要）
    let timeInBed: Double
    
    /// 睡眠効率（0.0〜1.0）
    let sleepEfficiency: Double?
    
    /// 睡眠潜時（秒）- 床に入ってから眠りに落ちるまでの時間
    let sleepLatency: Double?
    
    /// 睡眠途中覚醒時間（秒）- Wake After Sleep Onset
    let waso: Double?
    
    /// 就寝時間のばらつき（秒）- 標準偏差
    let sleepTimeVariability: Double?
    
    /// 起床時間のばらつき（秒）- 標準偏差
    let wakeTimeVariance: Double?
    
    /// 睡眠規則性指標（0〜100）- 追加
    let sleepRegularityIndex: Double?
    
    // --- 主観的評価 --- 
    /// 主観的な睡眠の質（1〜5）
    let subjectiveSleepQuality: Int?
    /// 主観的な睡眠の規則性（1〜5）
    let subjectiveSleepRegularity: Int?
    /// 主観的な入眠潜時の評価（1〜5）
    let subjectiveSleepLatency: Int?
    /// 主観的な睡眠途中覚醒の評価（1〜5）
    let subjectiveWaso: Int?
    /// 主観的眠気（1-10、オプション） - 追加
    let subjectiveSleepiness: Int?
    
    /// ウェアラブルデータの有無 - 追加
    let hasWearableData: Bool
    

    /// 初期化メソッド
    /// - Parameters:
    ///   - totalSleepTime: 総睡眠時間（秒）
    ///   - idealSleepTime: 理想睡眠時間（秒）
    ///   - timeInBed: ベッド内時間（秒）
    ///   - sleepEfficiency: 睡眠効率（パーセント）
    ///   - sleepLatency: 入眠潜時（秒）
    ///   - waso: 睡眠途中覚醒時間（秒）
    ///   - sleepTimeVariability: 就寝時間のばらつき（秒）
    ///   - wakeTimeVariability: 起床時間のばらつき（秒）
    ///   - sleepRegularityIndex: 睡眠規則性指標（0〜100）
    ///   - subjectiveSleepQuality: 主観的睡眠の質（1-5）
    ///   - subjectiveSleepLatency: 主観的入眠潜時（1-5）
    ///   - subjectiveSleepRegularity: 主観的睡眠の規則性（1-5）
    ///   - subjectiveWaso: 主観的睡眠途中覚醒（1-5）
    ///   - subjectiveSleepiness: 主観的眠気（1-10）
    ///   - hasWearableData: ウェアラブルデータの有無
    init(
        totalSleepTime: Double,
        idealSleepTime: Double,
        timeInBed: Double,
        sleepEfficiency: Double? = nil,
        sleepLatency: Double? = nil,
        waso: Double? = nil,
        sleepTimeVariability: Double? = nil,
        wakeTimeVariability: Double? = nil,
        sleepRegularityIndex: Double? = nil,
        subjectiveSleepQuality: Int? = nil,
        subjectiveSleepLatency: Int? = nil,
        subjectiveSleepRegularity: Int? = nil,
        subjectiveWaso: Int? = nil,
        subjectiveSleepiness: Int? = nil,
        hasWearableData: Bool
    ) {
        self.totalSleepTime = totalSleepTime
        self.idealSleepTime = idealSleepTime
        self.timeInBed = timeInBed
        self.sleepEfficiency = sleepEfficiency
        self.sleepLatency = sleepLatency
        self.waso = waso
        self.sleepTimeVariability = sleepTimeVariability
        self.wakeTimeVariance = wakeTimeVariability
        self.sleepRegularityIndex = sleepRegularityIndex
        self.subjectiveSleepQuality = subjectiveSleepQuality
        self.subjectiveSleepLatency = subjectiveSleepLatency
        self.subjectiveSleepRegularity = subjectiveSleepRegularity
        self.subjectiveWaso = subjectiveWaso
        self.subjectiveSleepiness = subjectiveSleepiness
        self.hasWearableData = hasWearableData
    }
    
    /// SleepRecordから睡眠の質データを生成する
    /// - Parameters:
    ///   - record: 睡眠記録 (Core DataのSleepRecord)
    ///   - sleepHistoryEntries: 過去の睡眠記録（規則性計算用）
    ///   - windowDays: 規則性計算の対象日数
    ///   - idealSleepDurationProvider: 年齢などから理想睡眠時間(秒)を返す関数 (例: SleepManager.getIdealSleepDuration)
    /// - Returns: 睡眠の質データ
    static func fromSleepEntry(
        _ record: SleepRecord, // Changed parameter type to SleepRecord
        sleepHistoryEntries: [SleepRecord], // Changed parameter type to [SleepRecord]
        windowDays: Int = 7,
        idealSleepDurationProvider: () -> Double // idealSleepTimeを外部から注入
    ) -> SleepQualityData {
        // 基本的な睡眠データを取得 (SleepRecordから)
        let startTime = record.startAt ?? Date()
        let endTime = record.endAt ?? startTime
        let totalSleepTime = endTime.timeIntervalSince(startTime)
        
        // --- SleepRecord に直接対応しない値は一旦プレースホルダー --- 
        // TODO: これらの値をHealthKitやユーザー入力から取得する方法を検討する
        let sleepLatency: Double? = nil // Placeholder - 入眠潜時
        let waso: Double? = nil       // Placeholder - 中途覚醒時間
        // 効率計算のためにベッド内時間が必要だが、SleepRecordにないため総睡眠時間で代用
        let timeInBed = totalSleepTime // Placeholder - ベッド内時間
        // --------------------------------------------------------

        // 睡眠効率を計算 (ベッド内時間のプレースホルダーを使用)
        let sleepEfficiency = timeInBed > 0 ? totalSleepTime / timeInBed : nil

        // 規則性（時間のばらつき）を計算
        let (sleepTimeVar, wakeTimeVar) = calculateTimeVariability(
            currentRecord: record, // Pass SleepRecord
            historyEntries: sleepHistoryEntries, // Pass [SleepRecord]
            windowDays: windowDays
        )
        
        // 睡眠規則性指標を計算 (ばらつきから推定)
        let sleepRegularityIndex = calculateSleepRegularityIndex(sleepTimeVariability: sleepTimeVar, wakeTimeVariability: wakeTimeVar)

        // 主観データ (SleepRecordのqualityを使用)
        let subjectiveSleepQuality = Int(record.quality)
        let subjectiveSleepiness = subjectiveSleepQuality // 主観的眠気もqualityで代用 (TODO: 分けるべきか検討)
        let subjectiveSleepLatency: Int? = nil // Placeholder
        let subjectiveWaso: Int? = nil       // Placeholder
        let subjectiveSleepRegularity = estimateRegularity( // 規則性はばらつきから推定
            sleepTimeVariability: sleepTimeVar,
            wakeTimeVariability: wakeTimeVar
        )
        
        // ウェアラブルデータの有無 (潜時やWASOが取れればTrueとしたいが、現状はFalse)
        let hasWearableData = sleepLatency != nil || waso != nil // Currently false

        // 理想睡眠時間を外部から取得
        let idealSleepTime = idealSleepDurationProvider()

        return SleepQualityData(
            totalSleepTime: totalSleepTime,
            idealSleepTime: idealSleepTime,
            timeInBed: timeInBed,
            sleepEfficiency: sleepEfficiency,
            sleepLatency: sleepLatency,
            waso: waso,
            sleepTimeVariability: sleepTimeVar,
            wakeTimeVariability: wakeTimeVar,
            sleepRegularityIndex: sleepRegularityIndex,
            subjectiveSleepQuality: subjectiveSleepQuality,
            subjectiveSleepLatency: subjectiveSleepLatency,
            subjectiveSleepRegularity: subjectiveSleepRegularity,
            subjectiveWaso: subjectiveWaso,
            subjectiveSleepiness: subjectiveSleepiness,
            hasWearableData: hasWearableData
        )
    }
    
    // MARK: - プライベートヘルパーメソッド
    
    /// 睡眠効率を計算
    /// - Parameter record: 睡眠記録 (Core DataのSleepRecord)
    /// - Returns: 睡眠効率（パーセント）
    private static func calculateSleepEfficiency(record: SleepRecord) -> Double? {
        guard let start = record.startAt, let end = record.endAt else { return nil }
        let duration = end.timeIntervalSince(start)
        // let bedDuration = record.bedDuration // SleepRecord doesn't have bedDuration directly
        // Assuming time in bed is the same as duration for now
        let timeInBed = duration // Placeholder
        guard timeInBed > 0 else {
            return nil
        }
        // 効率 = 睡眠時間 ÷ ベッドにいた時間
        return (duration / timeInBed)
    }

    /// 睡眠中の覚醒時間を計算
    /// - Parameter record: 睡眠記録 (Core DataのSleepRecord)
    /// - Returns: 睡眠中の覚醒時間（秒）
    private static func calculateWASO(record: SleepRecord) -> Double? {
        // Placeholder: WASO calculation needs data not present in SleepRecord
        return nil
    }

    /// 睡眠・起床時間のばらつきを計算
    /// - Parameters:
    ///   - currentRecord: 現在の睡眠記録 (Core DataのSleepRecord)
    ///   - historyEntries: 過去の睡眠記録 (Core DataのSleepRecord)
    ///   - windowDays: 計算対象日数
    /// - Returns: (就寝時間のばらつき, 起床時間のばらつき) タプル
    private static func calculateTimeVariability(
        currentRecord: SleepRecord, // Changed parameter type
        historyEntries: [SleepRecord], // Changed parameter type
        windowDays: Int
    ) -> (Double?, Double?) {
        // 最新のエントリを含めて直近の記録を取得
        var recentEntries = historyEntries
            .filter { ($0.startAt ?? Date.distantFuture) <= (currentRecord.startAt ?? Date.distantPast) && $0.id != currentRecord.id }
            .sorted { ($0.startAt ?? Date.distantPast) > ($1.startAt ?? Date.distantPast) }
        recentEntries.insert(currentRecord, at: 0)

        // windowDaysの日数分だけを使用
        let entries = Array(recentEntries.prefix(windowDays))

        // エントリが少なすぎる場合は計算しない
        if entries.count < 3 {
            return (nil, nil)
        }

        // 就寝時間と起床時間の配列を作成 (Use startAt and endAt)
        let sleepTimes = entries.compactMap { record -> Date? in
            guard let bedTime = record.startAt else { return nil }
            // 日付部分を無視して時間だけを比較するために時間を標準化
            return Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: bedTime),
                                         minute: Calendar.current.component(.minute, from: bedTime),
                                         second: Calendar.current.component(.second, from: bedTime),
                                         of: Date())
        }

        let wakeTimes = entries.compactMap { record -> Date? in
            guard let wakeTime = record.endAt else { return nil }
            // 日付部分を無視して時間だけを比較するために時間を標準化
            return Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: wakeTime),
                                         minute: Calendar.current.component(.minute, from: wakeTime),
                                         second: Calendar.current.component(.second, from: wakeTime),
                                         of: Date())
        }

        // 時間 (Date) の配列から標準偏差を計算 (秒単位)
        let sleepTimeVariability = calculateTimeStandardDeviation(sleepTimes)
        let wakeTimeVariability = calculateTimeStandardDeviation(wakeTimes)

        return (sleepTimeVariability, wakeTimeVariability)
    }
    
    /// 睡眠規則性指標を計算するヘルパー (0-100)
    private static func calculateSleepRegularityIndex(sleepTimeVariability: Double?, wakeTimeVariability: Double?) -> Double? {
        guard let sleepVar = sleepTimeVariability, let wakeVar = wakeTimeVariability else {
            return nil
        }
        // 就寝・起床時間のばらつきの平均（秒）
        let avgVariabilitySeconds = (sleepVar + wakeVar) / 2.0
        
        // ばらつきを0-1の範囲に正規化（例: 4時間以上のばらつきで0、0分のばらつきで1）
        let fourHoursInSeconds: Double = 4 * 60 * 60
        let normalizedVariability = max(0.0, 1.0 - (avgVariabilitySeconds / fourHoursInSeconds))
        
        // 0-100のスコアに変換
        return normalizedVariability * 100.0
    }
    
    /// 主観的な規則性を推定する (ばらつきデータから)
    /// - Parameters:
    ///   - sleepTimeVariability: 就寝時間のばらつき（秒）
    ///   - wakeTimeVariability: 起床時間のばらつき（秒）
    /// - Returns: 推定された主観的規則性（1-5）
    private static func estimateRegularity(sleepTimeVariability: Double?, wakeTimeVariability: Double?) -> Int? {
        guard let sleepVar = sleepTimeVariability, let wakeVar = wakeTimeVariability else {
            return nil // データがない場合は推定不可
        }
        
        // 平均ばらつき（分単位）
        let avgVariabilityMinutes = (sleepVar + wakeVar) / 2.0 / 60.0
        
        // ばらつきに基づいて1-5の評価を返す
        if avgVariabilityMinutes < 15 {
            return 5 // 非常に規則的
        } else if avgVariabilityMinutes < 30 {
            return 4 // 規則的
        } else if avgVariabilityMinutes < 60 {
            return 3 // やや不規則
        } else if avgVariabilityMinutes < 90 {
            return 2 // 不規則
        } else {
            return 1 // 非常に不規則
        }
    }
    
    /// Date配列の時間部分の標準偏差を計算するヘルパー関数
    private static func calculateTimeStandardDeviation(_ dates: [Date]) -> Double? {
        guard dates.count >= 2 else { return nil }
        
        // 基準となる日付（例：Unixエポック）からの経過秒数（時間部分のみ）に変換
        let referenceDate = Date(timeIntervalSince1970: 0)
        let secondsFromReference = dates.map { date -> Double in
            let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
            let timeOnlyDate = Calendar.current.date(bySettingHour: components.hour ?? 0,
                                                  minute: components.minute ?? 0,
                                                  second: components.second ?? 0,
                                                  of: referenceDate) ?? referenceDate
            return timeOnlyDate.timeIntervalSince(referenceDate)
        }
        
        // 平均値を計算
        let mean = secondsFromReference.reduce(0, +) / Double(secondsFromReference.count)
        
        // 分散を計算 (n-1で割る)
        let sumOfSquaredDiffs = secondsFromReference.reduce(0) { $0 + pow($1 - mean, 2) }
        // Avoid division by zero if count is 1, although guard should prevent this
        guard secondsFromReference.count > 1 else { return 0.0 }
        let variance = sumOfSquaredDiffs / Double(secondsFromReference.count - 1)
        
        // 標準偏差を返す
        return sqrt(variance)
    }
}