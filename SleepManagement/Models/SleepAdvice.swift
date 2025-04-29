import Foundation

/// 睡眠習慣に基づく専門家からのアドバイスを提供するモデル
struct SleepAdvice {
    /// アドバイスID
    let id: String
    
    /// アドバイスのタイトル
    let title: String
    
    /// 詳細なアドバイス内容
    let description: String
    
    /// アドバイスのカテゴリ
    let category: AdviceCategory
    
    /// アドバイスの優先度（1-10、高いほど重要）
    let priority: Int
    
    /// アドバイスのカテゴリ分類
    enum AdviceCategory: String, CaseIterable {
        case schedule = "睡眠スケジュールと一貫性"
        case routine = "睡眠前のルーティンと環境"
        case lifestyle = "生活習慣と睡眠の関係"
        case special = "特殊な睡眠状況への対応"
    }
    
    /// 睡眠データからアドバイスを生成する
    /// - Parameter data: 睡眠の質データ
    /// - Returns: 優先度順にソートされたアドバイスのリスト
    static func generateAdviceFrom(
        sleepData: SleepQualityData
    ) -> [SleepAdvice] {
        var adviceList: [SleepAdvice] = []
        
        // 条件1: 不規則な睡眠スケジュール
        if let timeVariability = sleepData.sleepTimeVariability, timeVariability > 3600 {
            adviceList.append(SleepAdvice(
                id: "irregular_sleep_schedule",
                title: "advice.irregular_sleep_schedule.title",
                description: "advice.irregular_sleep_schedule.description",
                category: .schedule,
                priority: 9
            ))
        }
        
        // 条件2: 睡眠負債の蓄積
        if sleepData.totalSleepTime < 7 * 3600 {
            let shortfall = (7 * 3600) - sleepData.totalSleepTime
            let shortfallHours = Int(shortfall / 3600)
            if shortfallHours > 0 {
                adviceList.append(SleepAdvice(
                    id: "sleep_debt",
                    title: "advice.sleep_debt.title",
                    description: String(format: NSLocalizedString("advice.sleep_debt.description", comment: ""), shortfallHours),
                    category: .schedule,
                    priority: 8
                ))
            }
        }
        
        // 条件3: 適切な睡眠時間の目安
        if abs(sleepData.totalSleepTime - sleepData.idealSleepTime) > 3600 {
            let diff = sleepData.totalSleepTime - sleepData.idealSleepTime
            let diffHours = Int(abs(diff) / 3600)
            adviceList.append(SleepAdvice(
                id: "ideal_sleep_duration",
                title: "advice.ideal_sleep_duration.title",
                description: String(format: NSLocalizedString("advice.ideal_sleep_duration.description", comment: ""), diffHours),
                category: .schedule,
                priority: 7
            ))
        }
        
        // 条件4: 睡眠効率の問題
        if let efficiency = sleepData.sleepEfficiency, efficiency < 0.85 {
            adviceList.append(SleepAdvice(
                id: "low_sleep_efficiency",
                title: "advice.low_sleep_efficiency.title",
                description: String(format: NSLocalizedString("advice.low_sleep_efficiency.description", comment: ""), Int(efficiency * 100)),
                category: .routine,
                priority: 8
            ))
        }
        
        // 条件5: 入眠潜時の問題
        if let latency = sleepData.sleepLatency, latency > 30 * 60 {
            adviceList.append(SleepAdvice(
                id: "long_sleep_latency",
                title: "advice.long_sleep_latency.title",
                description: "advice.long_sleep_latency.description",
                category: .routine,
                priority: 7
            ))
        }
        
        // 条件6: 睡眠中の覚醒問題
        if let waso = sleepData.waso, waso > 30 * 60 {
            adviceList.append(SleepAdvice(
                id: "frequent_wakeups",
                title: "advice.frequent_wakeups.title",
                description: "advice.frequent_wakeups.description",
                category: .special,
                priority: 7
            ))
        }
        
        // 条件7: 睡眠の規則性スコア
        if let regularityIndex = sleepData.sleepRegularityIndex, regularityIndex < 70 {
            adviceList.append(SleepAdvice(
                id: "low_sleep_regularity",
                title: "advice.low_sleep_regularity.title",
                description: "advice.low_sleep_regularity.description",
                category: .schedule,
                priority: 8
            ))
        }
        
        // 条件8: 主観的な睡眠の質が低い
        if let subjective = sleepData.subjectiveSleepQuality, subjective <= 2 {
            adviceList.append(SleepAdvice(
                id: "low_subjective_quality",
                title: "advice.low_subjective_quality.title",
                description: "advice.low_subjective_quality.description",
                category: .special,
                priority: 6
            ))
        }
        
        // 優先度でソート
        return adviceList.sorted { $0.priority > $1.priority }
    }
} 