import SwiftUI

struct SleepSessionEditView: View {
    let session: SleepSession
    let onSave: (SleepSession) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var startDate: Date
    @State private var endDate: Date
    
    init(session: SleepSession, onSave: @escaping (SleepSession) -> Void) {
        self.session = session
        self.onSave = onSave
        _startDate = State(initialValue: session.start)
        _endDate = State(initialValue: session.end)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("開始時刻")) {
                    DatePicker("", selection: $startDate, displayedComponents: [.hourAndMinute, .date])
                        .datePickerStyle(.wheel)
                }
                
                Section(header: Text("終了時刻")) {
                    DatePicker("", selection: $endDate, displayedComponents: [.hourAndMinute, .date])
                        .datePickerStyle(.wheel)
                }
                
                Section {
                    HStack {
                        Text("入床時間")
                        Spacer()
                        Text(durationText(endDate.timeIntervalSince(startDate)))
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("睡眠ログを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let updatedSession = SleepSession(
                            id: session.id,
                            segments: [
                                SleepSegment(id: UUID(), state: .inBed, start: startDate, end: endDate),
                                SleepSegment(id: UUID(), state: .asleepUnspecified, start: startDate, end: endDate)
                            ]
                        )
                        onSave(updatedSession)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func durationText(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval.truncatingRemainder(dividingBy: 3600)) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }
} 