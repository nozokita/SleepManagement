import SwiftUI

struct SleepSessionListView: View {
    @StateObject private var viewModel = SleepSessionViewModel()
    var date: Date = Date()
    
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: SleepSession?
    @State private var sessionToEdit: SleepSession?
    @State private var showScoreInfo = false

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
                    Text("sleep_log_no_data".localized)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.sessions) { session in
                        ZStack(alignment: .topTrailing) {
                            // スコアと詳細を横並びで表示
                            HStack(alignment: .center, spacing: 16) {
                                SleepScoreView(
                                    score: Double(session.sessionScore),
                                    size: 60,
                                    showText: true,
                                    showAnimation: false
                                )
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(timeFormatter.string(from: session.start))
                                            .font(.headline)
                                        Text("〜")
                                        Text(timeFormatter.string(from: session.end))
                                            .font(.headline)
                                        Spacer()
                                        if session.isNap {
                                            Text("nap".localized)
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                    }
                                    HStack {
                                        Text("in_bed_time".localized)
                                        Text(durationText(session.totalInBed))
                                            .bold()
                                        Spacer()
                                        Text("sleep_duration".localized)
                                        Text(durationText(session.totalAsleep))
                                            .bold()
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                sessionToEdit = session
                            }

                            // 情報アイコン
                            Button(action: { showScoreInfo = true }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(Theme.Colors.subtext)
                            }
                            .padding(8)
                        }
                        .padding(.vertical, 12)
                        .alert("score_info_title".localized, isPresented: $showScoreInfo) {
                            Button("common.okButton".localized, role: .cancel) {}
                        } message: {
                            Text("score_info_message".localized)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                sessionToDelete = session
                                showingDeleteAlert = true
                            } label: {
                                Label("list.delete".localized, systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("sleep_log_tab".localized)
            .task {
                print("SleepSessionListView: Starting to fetch sessions")
                await viewModel.fetchSessions(for: date)
                print("SleepSessionListView: Fetched \(viewModel.sessions.count) sessions")
            }
            .alert("delete_session_title".localized, isPresented: $showingDeleteAlert) {
                Button("cancel".localized, role: .cancel) { }
                Button("list.delete".localized, role: .destructive) {
                    if let session = sessionToDelete {
                        viewModel.deleteSession(session)
                    }
                }
            } message: {
                Text("delete_session_message".localized)
            }
            .sheet(item: $sessionToEdit) { session in
                SleepSessionEditView(session: session) { updatedSession in
                    viewModel.updateSession(updatedSession)
                }
            }
        }
    }
}

struct SleepSessionListView_Previews: PreviewProvider {
    static var previews: some View {
        SleepSessionListView()
    }
} 