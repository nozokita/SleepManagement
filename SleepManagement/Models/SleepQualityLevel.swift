import Foundation
import SwiftUI

/// 睡眠の質レベル（スコアの区分）
enum SleepQualityLevel: String, CaseIterable, Identifiable {
    /// 最高（90-100点）
    case excellent
    /// 良い（75-89点）
    case good
    /// 普通（50-74点）
    case fair
    /// 悪い（0-49点）
    case poor
    /// 不明（データ不足）
    case unknown
    
    var id: String { rawValue }
    
    /// 日本語の表示名
    var localizedName: String {
        switch self {
        case .excellent:
            return NSLocalizedString("sleep_quality_level_excellent", comment: "Excellent sleep quality")
        case .good:
            return NSLocalizedString("sleep_quality_level_good", comment: "Good sleep quality")
        case .fair:
            return NSLocalizedString("sleep_quality_level_fair", comment: "Fair sleep quality")
        case .poor:
            return NSLocalizedString("sleep_quality_level_poor", comment: "Poor sleep quality")
        case .unknown:
            return NSLocalizedString("sleep_quality_level_unknown", comment: "Unknown sleep quality")
        }
    }
    
    /// 絵文字表現
    var emoji: String {
        switch self {
        case .excellent:
            return "🤩"
        case .good:
            return "😊"
        case .fair:
            return "😐"
        case .poor:
            return "😴"
        case .unknown:
            return "🤔"
        }
    }
    
    /// 色分け用のカラーコード
    var colorHex: String {
        switch self {
        case .excellent:
            return "#4CAF50" // Green
        case .good:
            return "#8BC34A" // Light Green
        case .fair:
            return "#FFC107" // Amber
        case .poor:
            return "#F44336" // Red
        case .unknown:
            return "#9E9E9E" // Grey
        }
    }
    
    /// SwiftUIでのカラー
    var color: Color {
        switch self {
        case .excellent: return Color.green
        case .good: return Color(UIColor(red: 0.5, green: 0.8, blue: 0.4, alpha: 1.0))
        case .fair: return Color.yellow
        case .poor: return Color.red
        case .unknown: return Color.gray
        }
    }
    
    /// スコアからレベルを取得
    static func forScore(_ score: Int) -> SleepQualityLevel {
        switch score {
        case 90...100:
            return .excellent
        case 75..<90:
            return .good
        case 60..<75:
            return .fair
        case 0..<60:
            return .poor
        default:
            return .unknown
        }
    }
    
    /// 各レベルの説明文
    var description: String {
        switch self {
        case .excellent:
            return NSLocalizedString("sleep_quality_advice_excellent", comment: "Description for excellent sleep quality")
        case .good:
            return NSLocalizedString("sleep_quality_advice_good", comment: "Description for good sleep quality")
        case .fair:
            return NSLocalizedString("sleep_quality_advice_fair", comment: "Description for fair sleep quality")
        case .poor:
            return NSLocalizedString("sleep_quality_advice_poor", comment: "Description for poor sleep quality")
        case .unknown:
            return NSLocalizedString("sleep_quality_advice_unknown", comment: "Description for unknown sleep quality")
        }
    }
    
    /// 睡眠の質に基づくアドバイス
    var advice: String {
        switch self {
        case .excellent:
            return NSLocalizedString("sleep_quality_advice_excellent", comment: "Advice for excellent sleep quality")
        case .good:
            return NSLocalizedString("sleep_quality_advice_good", comment: "Advice for good sleep quality")
        case .fair:
            return NSLocalizedString("sleep_quality_advice_fair", comment: "Advice for fair sleep quality")
        case .poor:
            return NSLocalizedString("sleep_quality_advice_poor", comment: "Advice for poor sleep quality")
        case .unknown:
            return NSLocalizedString("sleep_quality_advice_unknown", comment: "Advice for unknown sleep quality")
        }
    }
} 