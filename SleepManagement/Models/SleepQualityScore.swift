import Foundation

/// 睡眠の質スコア（100点満点）
struct SleepQualityScore {
    /// 総合スコア（0-100点）
    let totalScore: Int
    
    /// コンポーネントスコア内訳
    let componentScores: ComponentScores
    
    /// 睡眠の質レベル（総合スコアから算出）
    var qualityLevel: QualityLevel {
        switch totalScore {
        case 90...100:
            return .excellent
        case 75..<90:
            return .good
        case 50..<75:
            return .fair
        case 0..<50:
            return .poor
        default:
            return .unknown
        }
    }
    
    /// 睡眠の質レベル定義
    enum QualityLevel: String, CaseIterable {
        /// 最高（90-100点）
        case excellent = "excellent"
        /// 良い（75-89点）
        case good = "good"
        /// 普通（50-74点）
        case fair = "fair"
        /// 悪い（0-49点）
        case poor = "poor"
        /// 不明（データ不足）
        case unknown = "unknown"
    }
    
    /// コンポーネントスコア内訳
    struct ComponentScores {
        /// 総睡眠時間スコア（0-40点）
        let durationScore: Int
        /// 睡眠効率スコア（0-25点）
        let efficiencyScore: Int
        /// 睡眠の規則性スコア（0-15点）
        let regularityScore: Int
        /// 入眠潜時スコア（0-10点）
        let latencyScore: Int
        /// 睡眠途中覚醒スコア（0-10点）
        let wasoScore: Int
        
        /// 総合スコアを計算
        var total: Int {
            return durationScore + efficiencyScore + regularityScore + latencyScore + wasoScore
        }
    }
    
    /// SleepQualityDataから睡眠の質スコアを計算
    /// - Parameter data: 睡眠の質計算に使用するデータ
    /// - Returns: 計算された睡眠の質スコア
    static func calculate(from data: SleepQualityData) -> SleepQualityScore {
        // 各コンポーネントスコアを計算
        let durationScore = calculateDurationScore(totalSleepTime: data.totalSleepTime)
        let efficiencyScore = calculateEfficiencyScore(
            sleepEfficiency: data.sleepEfficiency, 
            subjectiveQuality: data.subjectiveSleepQuality
        )
        let regularityScore = calculateRegularityScore(
            sleepTimeVariability: data.sleepTimeVariability,
            wakeTimeVariability: data.wakeTimeVariance,
            subjectiveRegularity: data.subjectiveSleepRegularity
        )
        let latencyScore = calculateLatencyScore(
            sleepLatency: data.sleepLatency,
            subjectiveLatency: data.subjectiveSleepLatency
        )
        let wasoScore = calculateWasoScore(
            waso: data.waso,
            subjectiveWaso: data.subjectiveWaso
        )
        
        // コンポーネントスコアを集約
        let componentScores = ComponentScores(
            durationScore: durationScore,
            efficiencyScore: efficiencyScore,
            regularityScore: regularityScore,
            latencyScore: latencyScore,
            wasoScore: wasoScore
        )
        
        // 総合スコアを計算（コンポーネントスコアの合計）
        return SleepQualityScore(
            totalScore: componentScores.total,
            componentScores: componentScores
        )
    }
    
    /// 総睡眠時間のスコアを計算（0-40点）
    /// - Parameter totalSleepTime: 総睡眠時間（秒）
    /// - Returns: 睡眠時間スコア
    private static func calculateDurationScore(totalSleepTime: Double) -> Int {
        // 睡眠時間を時間単位に変換
        let hoursSlept = totalSleepTime / 3600.0
        
        // 7-9時間を理想的な睡眠時間とする
        if hoursSlept >= 7.0 && hoursSlept <= 9.0 {
            return 40 // 最高スコア
        } else if hoursSlept >= 6.0 && hoursSlept < 7.0 {
            return 30 // やや短い
        } else if hoursSlept > 9.0 && hoursSlept <= 10.0 {
            return 30 // やや長い
        } else if hoursSlept >= 5.0 && hoursSlept < 6.0 {
            return 20 // 短い
        } else if hoursSlept > 10.0 && hoursSlept <= 11.0 {
            return 20 // 長い
        } else if hoursSlept >= 4.0 && hoursSlept < 5.0 {
            return 10 // かなり短い
        } else if hoursSlept > 11.0 {
            return 10 // かなり長い
        } else {
            return 0 // 非常に短い（4時間未満）
        }
    }
    
    /// 睡眠効率のスコアを計算（0-25点）
    /// - Parameters:
    ///   - sleepEfficiency: 睡眠効率（0.0-1.0）
    ///   - subjectiveQuality: 主観的な睡眠の質（1-5）
    /// - Returns: 睡眠効率スコア
    private static func calculateEfficiencyScore(sleepEfficiency: Double?, subjectiveQuality: Int?) -> Int {
        // 睡眠効率データがある場合はそれを優先
        if let efficiency = sleepEfficiency {
            // 睡眠効率を0-25点のスコアに変換
            if efficiency >= 0.95 {
                return 25 // 最高スコア
            } else if efficiency >= 0.90 {
                return 20
            } else if efficiency >= 0.85 {
                return 15
            } else if efficiency >= 0.80 {
                return 10
            } else if efficiency >= 0.75 {
                return 5
            } else {
                return 0 // 非常に低い睡眠効率
            }
        }
        
        // 睡眠効率データがない場合は主観的な睡眠の質を使用
        else if let quality = subjectiveQuality {
            // 主観的評価を0-25点のスコアに変換
            switch quality {
            case 5: return 25 // とても良い
            case 4: return 20 // 良い
            case 3: return 15 // 普通
            case 2: return 5  // 悪い
            case 1: return 0  // とても悪い
            default: return 0
            }
        }
        
        // どちらのデータもない場合はデフォルト値
        else {
            return 15 // 中間値を返す
        }
    }
    
    /// 睡眠の規則性スコアを計算（0-15点）
    /// - Parameters:
    ///   - sleepTimeVariability: 就寝時間のばらつき（秒）
    ///   - wakeTimeVariability: 起床時間のばらつき（秒）
    ///   - subjectiveRegularity: 主観的な睡眠の規則性（1-5）
    /// - Returns: 睡眠の規則性スコア
    private static func calculateRegularityScore(
        sleepTimeVariability: Double?,
        wakeTimeVariability: Double?,
        subjectiveRegularity: Int?
    ) -> Int {
        // 就寝・起床時間のばらつきがある場合はそれを使用
        if let sleepVar = sleepTimeVariability, let wakeVar = wakeTimeVariability {
            // 就寝・起床時間のばらつきの平均（分単位に変換）
            let avgVariabilityMinutes = (sleepVar + wakeVar) / 2 / 60
            
            // ばらつきを0-15点のスコアに変換
            if avgVariabilityMinutes < 15 {
                return 15 // 非常に規則的
            } else if avgVariabilityMinutes < 30 {
                return 12
            } else if avgVariabilityMinutes < 45 {
                return 9
            } else if avgVariabilityMinutes < 60 {
                return 6
            } else if avgVariabilityMinutes < 90 {
                return 3
            } else {
                return 0 // 非常に不規則
            }
        }
        
        // ばらつきデータがない場合は主観的な規則性を使用
        else if let regularity = subjectiveRegularity {
            // 主観的評価を0-15点のスコアに変換
            switch regularity {
            case 5: return 15 // とても規則的
            case 4: return 12 // 規則的
            case 3: return 9  // やや規則的
            case 2: return 3  // 不規則
            case 1: return 0  // とても不規則
            default: return 0
            }
        }
        
        // どちらのデータもない場合はデフォルト値
        else {
            return 7 // 中間値を返す
        }
    }
    
    /// 入眠潜時のスコアを計算（0-10点）
    /// - Parameters:
    ///   - sleepLatency: 入眠潜時（秒）
    ///   - subjectiveLatency: 主観的な入眠潜時の評価（1-5）
    /// - Returns: 入眠潜時スコア
    private static func calculateLatencyScore(sleepLatency: Double?, subjectiveLatency: Int?) -> Int {
        // 入眠潜時データがある場合はそれを使用
        if let latency = sleepLatency {
            // 入眠潜時を分単位に変換
            let latencyMinutes = latency / 60
            
            // 入眠潜時を0-10点のスコアに変換
            if latencyMinutes <= 5 {
                return 10 // 理想的（5分以下）
            } else if latencyMinutes <= 15 {
                return 8 // 良好（5-15分）
            } else if latencyMinutes <= 30 {
                return 6 // 普通（15-30分）
            } else if latencyMinutes <= 60 {
                return 3 // 長い（30-60分）
            } else {
                return 0 // 非常に長い（60分以上）
            }
        }
        
        // 入眠潜時データがない場合は主観的な評価を使用
        else if let latencyRating = subjectiveLatency {
            // 主観的評価を0-10点のスコアに変換
            switch latencyRating {
            case 5: return 10 // とても早く眠れた
            case 4: return 8  // 早く眠れた
            case 3: return 6  // 普通
            case 2: return 3  // 眠りにくかった
            case 1: return 0  // とても眠りにくかった
            default: return 0
            }
        }
        
        // どちらのデータもない場合はデフォルト値
        else {
            return 5 // 中間値を返す
        }
    }
    
    /// 睡眠途中覚醒（WASO）のスコアを計算（0-10点）
    /// - Parameters:
    ///   - waso: 睡眠途中覚醒時間（秒）
    ///   - subjectiveWaso: 主観的な睡眠途中覚醒の評価（1-5）
    /// - Returns: WASO（睡眠途中覚醒）スコア
    private static func calculateWasoScore(waso: Double?, subjectiveWaso: Int?) -> Int {
        // WASO データがある場合はそれを使用
        if let wasoTime = waso {
            // WASO を分単位に変換
            let wasoMinutes = wasoTime / 60
            
            // WASO を0-10点のスコアに変換
            if wasoMinutes < 10 {
                return 10 // 理想的（10分未満）
            } else if wasoMinutes < 20 {
                return 8 // 良好（10-20分）
            } else if wasoMinutes < 30 {
                return 6 // 普通（20-30分）
            } else if wasoMinutes < 60 {
                return 3 // 多い（30-60分）
            } else {
                return 0 // 非常に多い（60分以上）
            }
        }
        
        // WASO データがない場合は主観的な評価を使用
        else if let wasoRating = subjectiveWaso {
            // 主観的評価を0-10点のスコアに変換
            switch wasoRating {
            case 5: return 10 // ほとんど目覚めなかった
            case 4: return 8  // あまり目覚めなかった
            case 3: return 6  // 少し目覚めた
            case 2: return 3  // よく目覚めた
            case 1: return 0  // 非常によく目覚めた
            default: return 0
            }
        }
        
        // どちらのデータもない場合はデフォルト値
        else {
            return 5 // 中間値を返す
        }
    }
    
    /// 初期化
    /// - Parameters:
    ///   - totalScore: 総合スコア
    ///   - componentScores: コンポーネントスコア内訳
    init(totalScore: Int, componentScores: ComponentScores) {
        self.totalScore = totalScore
        self.componentScores = componentScores
    }
} 