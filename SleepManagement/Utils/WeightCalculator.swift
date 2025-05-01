import Foundation

/// 睡眠エピソードの長さに基づく回復効率の係数を計算するユーティリティ
/// Calculates the recovery weight factor based on sleep duration in minutes.
struct WeightCalculator {
    /// 重み付け関数 w(d)：質×時間の回復係数を返す
    /// - Parameter minutes: 睡眠エピソードの継続時間（分）/ duration of the sleep episode in minutes
    /// - Returns: 回復効率の係数 (0.0–1.0) / a factor representing recovery efficiency
    static func w(_ minutes: Int) -> Double {
        switch minutes {
        case ..<10:
            return 0.0
        case 10..<30:
            return 0.3
        case 30..<60:
            return 0.6
        case 60..<90:
            return 0.9
        default:
            return 1.0
        }
    }
} 