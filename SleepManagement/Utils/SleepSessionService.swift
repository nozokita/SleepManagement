import Foundation
import HealthKit

// SleepQueryServiceから取得したSleepSegmentを一晩の睡眠セッションにまとめるモデル
struct SleepSession: Identifiable {
    let id = UUID()
    let segments: [SleepSegment]
    var start: Date { segments.first?.start ?? Date() }
    var end: Date { segments.last?.end ?? Date() }
    var totalInBed: TimeInterval { end.timeIntervalSince(start) }
    var totalAsleep: TimeInterval {
        segments.filter { $0.state.isAsleep }
                .reduce(0) { $0 + $1.duration }
    }
}

// SleepSegment.stateに簡易的に「眠っているか」を判定するプロパティを追加
extension HKCategoryValueSleepAnalysis {
    var isAsleep: Bool {
        switch self {
        case .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM:
            return true
        default:
            return false
        }
    }
}

// SleepSegmentを受け取り、連続したセグメントを一定間隔内でまとめてSleepSessionに変換するサービス
actor SleepSessionService {
    private let queryService: SleepQueryService
    private let gapThreshold: TimeInterval

    init(queryService: SleepQueryService, gapThreshold: TimeInterval = 30 * 60) {
        self.queryService = queryService
        self.gapThreshold = gapThreshold
    }

    /// 指定日の0:00～翌日0:00のSleepSegmentを取得し、隙間がgapThreshold以内であれば同一セッションとしてまとめて返します
    func fetchSessions(for date: Date) async throws -> [SleepSession] {
        let segments = try await queryService.fetchSegments(for: date)
        let sorted = segments.sorted { $0.start < $1.start }
        var sessions: [[SleepSegment]] = []

        for segment in sorted {
            if let lastSession = sessions.last, let lastSeg = lastSession.last {
                if segment.start.timeIntervalSince(lastSeg.end) <= gapThreshold {
                    // 同じセッションに追加
                    sessions[sessions.count - 1].append(segment)
                } else {
                    // 新規セッション開始
                    sessions.append([segment])
                }
            } else {
                // 最初のセッション
                sessions.append([segment])
            }
        }
        return sessions.map { SleepSession(segments: $0) }
    }
} 