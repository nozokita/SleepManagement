import Foundation

@MainActor
final class SleepSessionViewModel: ObservableObject {
    @Published var sessions: [SleepSession] = []
    private let service: SleepSessionService

    init(service: SleepSessionService = .init(queryService: SleepQueryService(store: HealthKitManager.shared.healthStore))) {
        self.service = service
    }

    /// 指定日のセッション一覧をフェッチして `sessions` に格納します。
    /// - Parameter date: 対象日（デフォルトは本日）
    func fetchSessions(for date: Date = Date()) async {
        do {
            let result = try await service.fetchSessions(for: date)
            // 取得結果を一時格納
            var loaded = result
            // シミュレーター専用のダミーデータ（実データ0件の場合）
            #if targetEnvironment(simulator)
            if loaded.isEmpty {
                print("SleepSessionViewModel: Adding dummy data for simulator")
                loaded = createDummySessions(for: date)
            }
            #endif
            // 設定に応じてフィルタ：開始>=終了（誤入力）と仮眠扱いを除外
            let filtered = loaded.filter { session in
                // 開始時刻が終了時刻以上なら除外
                if session.end <= session.start {
                    return false
                }
                // 短い睡眠を仮眠扱いにする設定がオンの場合、isNap=true のセッションを除外
                if SettingsManager.shared.treatShortSleepAsNap && session.isNap {
                    return false
                }
                return true
            }
            sessions = filtered
            print("SleepSessionViewModel: Fetched \(sessions.count) sessions")
            // 各セッションのスコアを出力
            for (i, session) in sessions.enumerated() {
                print("Session[\(i)]: start=\(session.start), end=\(session.end), score=\(session.sessionScore)")
            }
        } catch {
            print("Error fetching sleep sessions: \(error)")
            sessions = []
        }
    }
    
    /// セッションを削除します
    func deleteSession(_ session: SleepSession) {
        sessions.removeAll { $0.id == session.id }
    }
    
    /// セッションを更新します
    func updateSession(_ updatedSession: SleepSession) {
        if let index = sessions.firstIndex(where: { $0.id == updatedSession.id }) {
            sessions[index] = updatedSession
        }
    }
    
    // シミュレーター用のダミーデータ生成
    private func createDummySessions(for date: Date) -> [SleepSession] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // 1. 通常の睡眠セッション（23:00-7:00）
        let mainSleepStart = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: dayStart)!
        let mainSleepEnd = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: dayStart)!
        
        // 2. 短い仮眠（15:00-15:30）
        let napStart = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dayStart)!
        let napEnd = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: dayStart)!
        
        // 3. 不規則な睡眠パターン（1:00-4:00, 5:00-7:00）
        let irregularStart1 = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: dayStart)!
        let irregularEnd1 = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: dayStart)!
        let irregularStart2 = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: dayStart)!
        let irregularEnd2 = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: dayStart)!
        
        // 4. 非常に短い睡眠（10:00-10:15）
        let veryShortStart = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dayStart)!
        let veryShortEnd = calendar.date(bySettingHour: 10, minute: 15, second: 0, of: dayStart)!
        
        // 5. 長い仮眠（13:00-15:00）
        let longNapStart = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: dayStart)!
        let longNapEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dayStart)!
        
        // 各セッションのセグメント
        let mainSegments = [
            SleepSegment(id: UUID(), state: .inBed, start: mainSleepStart, end: mainSleepEnd),
            SleepSegment(id: UUID(), state: .asleepUnspecified, start: mainSleepStart, end: mainSleepEnd)
        ]
        
        let napSegments = [
            SleepSegment(id: UUID(), state: .inBed, start: napStart, end: napEnd),
            SleepSegment(id: UUID(), state: .asleepUnspecified, start: napStart, end: napEnd)
        ]
        
        let irregularSegments1 = [
            SleepSegment(id: UUID(), state: .inBed, start: irregularStart1, end: irregularEnd1),
            SleepSegment(id: UUID(), state: .asleepUnspecified, start: irregularStart1, end: irregularEnd1)
        ]
        
        let irregularSegments2 = [
            SleepSegment(id: UUID(), state: .inBed, start: irregularStart2, end: irregularEnd2),
            SleepSegment(id: UUID(), state: .asleepUnspecified, start: irregularStart2, end: irregularEnd2)
        ]
        
        let veryShortSegments = [
            SleepSegment(id: UUID(), state: .inBed, start: veryShortStart, end: veryShortEnd),
            SleepSegment(id: UUID(), state: .asleepUnspecified, start: veryShortStart, end: veryShortEnd)
        ]
        
        let longNapSegments = [
            SleepSegment(id: UUID(), state: .inBed, start: longNapStart, end: longNapEnd),
            SleepSegment(id: UUID(), state: .asleepUnspecified, start: longNapStart, end: longNapEnd)
        ]
        
        return [
            SleepSession(segments: mainSegments),      // 通常の睡眠
            SleepSession(segments: napSegments),       // 短い仮眠
            SleepSession(segments: irregularSegments1), // 不規則な睡眠1
            SleepSession(segments: irregularSegments2), // 不規則な睡眠2
            SleepSession(segments: veryShortSegments),  // 非常に短い睡眠
            SleepSession(segments: longNapSegments)     // 長い仮眠
        ]
    }
} 