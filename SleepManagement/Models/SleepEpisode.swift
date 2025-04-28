import Foundation
import SwiftData

/// 睡眠エピソードを表すモデル
/// Model representing a sleep episode for SwiftData persistence
@Model
final class SleepEpisode: Identifiable {
    @Attribute(.unique) var id: UUID
    /// 睡眠開始時刻 / Episode start timestamp
    var startAt: Date
    /// 睡眠終了時刻 / Episode end timestamp
    var endAt: Date
    /// 睡眠時間（分） / Sleep duration in minutes
    var durationMin: Int

    /// イニシャライザ
    init(id: UUID = .init(), startAt: Date, endAt: Date, durationMin: Int) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.durationMin = durationMin
    }
} 