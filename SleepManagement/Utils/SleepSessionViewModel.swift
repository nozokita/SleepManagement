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
            sessions = result
        } catch {
            print("Error fetching sleep sessions: \(error)")
            sessions = []
        }
    }
} 