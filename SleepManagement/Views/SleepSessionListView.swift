import SwiftUI

struct SleepSessionListView: View {
    @StateObject private var viewModel = SleepSessionViewModel()
    var date: Date = Date()

    // 時刻フォーマッタ
    private var timeFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df
    }
    // 時間・分フォーマッタ
    private func durationText(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval.truncatingRemainder(dividingBy: 3600)) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }

    var body: some View {
        NavigationView {
            List {
                if viewModel.sessions.isEmpty {
                    Text("該当日の睡眠セッションはありません")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.sessions) { session in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(timeFormatter.string(from: session.start))
                                    .font(.headline)
                                Text("〜")
                                Text(timeFormatter.string(from: session.end))
                                    .font(.headline)
                                Spacer()
                            }
                            HStack {
                                Text("入床時間: ")
                                Text(durationText(session.totalInBed))
                                    .bold()
                                Spacer()
                                Text("睡眠: ")
                                Text(durationText(session.totalAsleep))
                                    .bold()
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("睡眠セッション")
            .task {
                await viewModel.fetchSessions(for: date)
            }
        }
    }
}

struct SleepSessionListView_Previews: PreviewProvider {
    static var previews: some View {
        SleepSessionListView()
    }
} 