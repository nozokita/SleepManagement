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
                Section(header: Text("session.startTime".localized)) {
                    DatePicker("", selection: $startDate, displayedComponents: [.hourAndMinute, .date])
                        .datePickerStyle(.wheel)
                }
                
                Section(header: Text("session.endTime".localized)) {
                    DatePicker("", selection: $endDate, displayedComponents: [.hourAndMinute, .date])
                        .datePickerStyle(.wheel)
                }
                
                Section {
                    HStack {
                        Text("session.inBedTime".localized)
                        Spacer()
                        Text(durationText(endDate.timeIntervalSince(startDate)))
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("sleep_log_edit".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save".localized) {
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
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func durationText(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval.truncatingRemainder(dividingBy: 3600)) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }
} 