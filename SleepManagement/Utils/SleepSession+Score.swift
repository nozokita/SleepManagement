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

    /// セッション単位の睡眠スコア (0–100) を HealthKit モデルに変更
    var sessionScore: Int {
        // HealthKit マルチファクターモデルで 100 点満点で計算
        let durationH = totalAsleep / 3600.0
        let eff = efficiency
        // 規則性はセッション単体では未実装のため、1.0(完璧)と仮定
        let reg = 1.0
        // 潜時: 最初の入眠セグメント到達までの時間（分）
        let firstAsleep = segments.first(where: { $0.state.isAsleep })
        let lat = firstAsleep.map { $0.start.timeIntervalSince(start) / 60 } ?? 0.0
        // WASO: セッション中のAwakeセグメント合計時間（分）
        let waso = segments
            .filter { $0.state == .awake }
            .reduce(0.0) { $0 + $1.duration } / 60.0
        let score = SleepManager.shared.calculateHealthKitSleepScore(
            durationH: durationH,
            efficiency: eff,
            regularity: reg,
            latency: lat,
            waso: waso
        )
        return Int(max(0, min(score, 100)))
    }
} 