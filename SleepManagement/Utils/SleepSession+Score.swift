import Foundation

extension SleepSession {
    /// 覚醒回数を数えます
    var awakeCount: Int {
        segments.filter { $0.state == .awake }.count
    }

    /// 深睡眠時間（asleepDeep）の合計を取得します
    var deepSleepDuration: TimeInterval {
        segments
            .filter { $0.state == .asleepDeep }
            .map { $0.duration }
            .reduce(0, +)
    }

    /// 深睡眠の割合 (0.0–1.0)
    var deepSleepRatio: Double {
        guard totalAsleep > 0 else { return 0 }
        return deepSleepDuration / totalAsleep
    }

    /// 睡眠効率 (0.0–1.0)
    var efficiency: Double {
        guard totalInBed > 0 else { return 0 }
        return totalAsleep / totalInBed
    }

    /// セッション単位の睡眠スコア (0–100)
    var sessionScore: Int {
        // 効率（40点満点）
        let efficiencyScore = min(efficiency, 1.0) * 40.0
        // 覚醒ペナルティ（2点/回）
        let wakePenalty = Double(awakeCount) * 2.0
        // 深睡眠ボーナス（10点満点、深睡眠比率20%で満点）
        let deepBonus = min(deepSleepRatio / 0.2, 1.0) * 10.0
        // 合計とクランプ
        let rawScore = efficiencyScore - wakePenalty + deepBonus
        let clamped = max(0, min(rawScore, 100))
        return Int(clamped)
    }
} 