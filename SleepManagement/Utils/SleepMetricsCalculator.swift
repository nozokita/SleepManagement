import Foundation
import HealthKit

/// 各睡眠指標をまとめたモデル
struct SleepMetrics {
    var durationH: Double        // 総睡眠時間 [h]
    var efficiency: Double       // 睡眠効率 (0–1)
    var regularity: Double       // Sleep Regularity Index (0–100)
    var latency: Double          // 入眠潜時 [min]
    var waso: Double             // WASO [min]
}

/// 7日間分の SleepMetrics を計算するクラス
final class SleepMetricsCalculator {
    private let queryService: SleepQueryService  // Utils/SleepQueryService.swift で定義
    private let calendar = Calendar.current

    init(queryService: SleepQueryService) {
        self.queryService = queryService
    }

    /// 直近7日間の平均 SleepMetrics を返す
    func weeklyMetrics(endingAt date: Date = .now,
                       recommendedSleepHours: Double = 8.0) async throws -> SleepMetrics {
        var meta: [Date: (segments: [SleepSegment], onset: Date?, wake: Date?)] = [:]

        // 各日の睡眠セグメントを取得し、最初の就床・最後の起床を記録
        for i in 0..<7 {
            guard let target = calendar.date(byAdding: .day, value: -i, to: date) else { continue }
            let segs = try await queryService.fetchSegments(for: target)
            let asleepStates: Set<HKCategoryValueSleepAnalysis> = [
                .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM
            ]
            let onset = segs.first(where: { asleepStates.contains($0.state) })?.start
            let wake = segs.last?.end
            meta[target] = (segments: segs, onset: onset, wake: wake)
        }

        // 各指標をリストに集約
        var durations: [Double] = []
        var efficiencies: [Double] = []
        var onsets: [Date] = []
        var latencies: [Double] = []
        var wasos: [Double] = []

        for (_, info) in meta {
            guard let onset = info.onset, let wake = info.wake else { continue }
            let segments = info.segments

            // 総睡眠時間
            let sleepSecs = segments
                .filter { [.asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM].contains($0.state) }
                .reduce(0) { $0 + $1.duration }

            // 疑似就床区間
            let inBedSecs = wake.timeIntervalSince(onset)
            let efficiency = sleepSecs / inBedSecs

            // 入眠潜時は拡張可
            let latency = 0.0

            // WASO
            let wasoSecs = segments
                .filter { $0.state == .awake && $0.start >= onset && $0.end <= wake }
                .reduce(0) { $0 + $1.duration }

            durations.append(sleepSecs / 3600)
            efficiencies.append(efficiency)
            onsets.append(onset)
            latencies.append(latency / 60)
            wasos.append(wasoSecs / 60)
        }

        // 平均値と SRI 計算
        let avgDur = durations.average
        let avgEff = efficiencies.average
        let sri = SleepMetricsCalculator.sleepRegularityIndex(from: onsets)
        let avgLat = latencies.average
        let avgWaso = wasos.average

        return SleepMetrics(durationH: avgDur,
                             efficiency: avgEff,
                             regularity: sri,
                             latency: avgLat,
                             waso: avgWaso)
    }

    // SRI の簡易計算: 就床時刻差の平均を 100 から引いて正規化
    private static func sleepRegularityIndex(from onsets: [Date]) -> Double {
        guard onsets.count >= 2 else { return 100 }
        var diffs: [Double] = []
        for i in 1..<onsets.count {
            let diffH = abs(onsets[i].timeIntervalSince(onsets[i-1])) / 3600
            diffs.append(diffH)
        }
        let meanDiff = diffs.average
        return max(0, 100 - meanDiff * 100 / 24)
    }
}

/// Composite Sleep Score 計算関数
func compositeSleepScore(from m: SleepMetrics,
                         recommendedSleepHours: Double = 8.0) -> Double {
    let durScore  = 40.0 * min(m.durationH / recommendedSleepHours, 1.0)
    let effScore  = 25.0 * min(m.efficiency / 0.85, 1.0)
    let regScore  = 15.0 * (1.0 - m.regularity / 100.0)
    let latScore  = 10.0 * max(0, (30.0 - m.latency) / 30.0)
    let wasoScore = 10.0 * max(0, (30.0 - m.waso) / 30.0)
    return durScore + effScore + regScore + latScore + wasoScore
}

// ユーティリティ: Double 配列の平均値
private extension Array where Element == Double {
    var average: Double { isEmpty ? 0 : reduce(0, +) / Double(count) }
} 