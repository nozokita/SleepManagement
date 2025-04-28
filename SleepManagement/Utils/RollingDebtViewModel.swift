import Foundation
import SwiftData
import Combine

/// 過去24時間の睡眠データからローリング負債を計算する ViewModel
/// ViewModel that computes rolling sleep debt over the past 24 hours
@MainActor
final class RollingDebtViewModel: ObservableObject {
    /// SwiftData から取得した SleepEpisode 配列
    @Query(sort: \.startAt, order: .reverse) private var episodes: [SleepEpisode]

    /// 質×時間で重み付けした合計睡眠分
    @Published var effective24: Double = 0
    /// 急性負債（分単位）
    @Published var acuteDebt: Double = 0

    /// 理想睡眠分数 (分単位)
    private var idealMinutes: Double {
        SettingsManager.shared.idealSleepDuration / 60
    }

    private var timerCancellable: AnyCancellable?

    init() {
        // 初期計算
        calculateDebt()
        // 毎分再計算するタイマー
        timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.calculateDebt()
            }
    }

    /// 24時間内のエピソードをフィルタし、急性負債を計算する
    /// Filters episodes within last 24h and computes acute sleep debt
    private func calculateDebt() {
        let now = Date()
        let since = Calendar.current.date(byAdding: .hour, value: -24, to: now) ?? now
        let recent = episodes.filter { $0.endAt > since }

        // 重み付き睡眠時間の合計
        let weightedSum = recent.reduce(0.0) { sum, ep in
            let minutes = ep.durationMin
            return sum + WeightCalculator.w(minutes) * Double(minutes)
        }
        effective24 = weightedSum

        // 負債 = max(0, 理想分数 - 効果的睡眠分)
        acuteDebt = max(0, idealMinutes - weightedSum)
    }

    deinit {
        timerCancellable?.cancel()
    }
} 