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
    /// - Parameter past30DayAvgScore: 過去30日間の平均スコア
    /// - Returns: 優先度順にソートされたアドバイスのリスト
    static func generateAdviceFrom(
        sleepData: SleepQualityData,
        past30DayAvgScore: Double? = nil
    ) -> [SleepAdvice] {
        var adviceList: [SleepAdvice] = []
        
        // 条件1: 不規則な睡眠スケジュール (2時間以上)
        if let timeVariability = sleepData.sleepTimeVariability, timeVariability > 2 * 3600 {
            adviceList.append(SleepAdvice(
                id: "irregular_sleep_schedule",
                title: "advice.irregular_sleep_schedule.title",
                description: "advice.irregular_sleep_schedule.description",
                category: .schedule,
                priority: 9
            ))
        }
        
        // 条件2: 睡眠負債の蓄積 (6時間未満)
        if sleepData.totalSleepTime < 6 * 3600 {
            adviceList.append(SleepAdvice(
                id: "sleep_debt",
                title: "advice.sleep_debt.title",
                description: "advice.sleep_debt.description",
                category: .schedule,
                priority: 8
            ))
        }
        
        // 条件7: 睡眠の規則性スコア低下 (70未満)
        if let regularityIndex = sleepData.sleepRegularityIndex, regularityIndex < 70 {
            adviceList.append(SleepAdvice(
                id: "low_sleep_regularity",
                title: "advice.low_sleep_regularity.title",
                description: "advice.low_sleep_regularity.description",
                category: .schedule,
                priority: 8
            ))
        }
        
        // 条件8: 主観的な睡眠の質が低い (2以下)
        if let subjective = sleepData.subjectiveSleepQuality, subjective <= 2 {
            adviceList.append(SleepAdvice(
                id: "low_subjective_quality",
                title: "advice.low_subjective_quality.title",
                description: "advice.low_subjective_quality.description",
                category: .special,
                priority: 6
            ))
        }
        
        // 条件9: 長期的傾向の改善 (30日平均スコア65未満)
        if let avg = past30DayAvgScore, avg < 65.0 {
            adviceList.append(SleepAdvice(
                id: "long_term_trend",
                title: "advice.long_term_trend.title",
                description: "advice.long_term_trend.description",
                category: .lifestyle,
                priority: 6
            ))
        }
        
        // 優先度でソート
        return adviceList.sorted { $0.priority > $1.priority }
    }
} 