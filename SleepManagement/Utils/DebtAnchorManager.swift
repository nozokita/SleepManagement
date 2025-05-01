import Foundation
import SwiftData

/// 日次ウィンドウの基準時刻（anchor）を計算するユーティリティ
/// Utility to compute the daily debt anchor (24h window start) with shifting within ±6h
struct DebtAnchorManager {
    /// 指定日の anchor を計算する
    /// - Parameters:
    ///   - date: 計算対象日
    ///   - context: SwiftData の ModelContext
    /// - Returns: anchor として使う時刻（Date）
    static func anchor(for date: Date, context: ModelContext) -> Date {
        let calendar = Calendar.current
        // 当日の正午を初期 anchor に設定
        let dayStart = calendar.startOfDay(for: date)
        guard let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: dayStart) else {
            return date
        }

        // 過去7日間のエピソードを取得
        let startWindow = calendar.date(byAdding: .day, value: -6, to: dayStart)!
        let endWindow = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let descriptor = FetchDescriptor<SleepEpisode>(
            predicate: #Predicate { episode in
                episode.startAt >= startWindow && episode.startAt < endWindow
            },
            sortBy: [SortDescriptor(\.startAt, order: .forward)]
        )
        let episodes: [SleepEpisode] = (try? context.fetch(descriptor)) ?? []

        // 日ごとに最長エピソードを抽出し、その中心時刻を計算
        var centers: [Date] = []
        let grouped = Dictionary(grouping: episodes, by: { calendar.startOfDay(for: $0.startAt) })
        for (_, eps) in grouped {
            if let maxEpisode = eps.max(by: { $0.durationMin < $1.durationMin }) {
                let midInterval = (maxEpisode.endAt.timeIntervalSince(maxEpisode.startAt)) / 2
                let center = maxEpisode.startAt.addingTimeInterval(midInterval)
                centers.append(center)
            }
        }
        guard !centers.isEmpty else {
            return noon
        }

        // 中央値を取得
        let sortedCenters = centers.sorted()
        let median = sortedCenters[sortedCenters.count / 2]

        // ±6時間 (21600秒) の範囲にクランプ
        let maxOffset: TimeInterval = 6 * 3600
        let diff = median.timeIntervalSince(noon)
        if diff > maxOffset {
            return noon.addingTimeInterval(maxOffset)
        } else if diff < -maxOffset {
            return noon.addingTimeInterval(-maxOffset)
        } else {
            return median
        }
    }
} 