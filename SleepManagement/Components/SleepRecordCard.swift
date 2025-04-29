import SwiftUI

struct SleepRecordCard: View {
    let record: SleepRecord
    var onTap: () -> Void = {}
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 16) {
                // 睡眠スコア表示
                if SleepRecordType(rawValue: record.sleepType) == .nap {
                    Color.clear.frame(width: 60, height: 60)
                } else {
                    SleepScoreView(score: record.score, size: 60)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // 日付
                    Text(record.sleepDateText)
                        .font(Theme.Typography.subheadingFont)
                        .foregroundColor(Theme.Colors.text)
                    
                    // 睡眠時間
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text("\(record.startTimeText) - \(record.endTimeText)")
                            .font(Theme.Typography.bodyFont)
                            .foregroundColor(Theme.Colors.text)
                    }
                    
                    // 睡眠の長さ
                    HStack(spacing: 8) {
                        Image(systemName: "bed.double")
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text(record.durationText)
                            .font(Theme.Typography.bodyFont)
                            .foregroundColor(Theme.Colors.text)
                    }
                }
                
                Spacer()
                
                // 睡眠負債表示（あれば）
                if record.debt > 0 {
                    VStack {
                        Text("sleep_debt".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.subtext)
                        
                        Text(record.debtText)
                            .font(Theme.Typography.bodyFont.bold())
                            .foregroundColor(Theme.Colors.scoreColor(score: max(0, 100 - record.debt * 10)))
                    }
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.Colors.subtext)
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.Layout.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// プレビュー用のダミーレコード
struct SleepRecordCardPreview: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let record = SleepRecord(context: context)
        record.id = UUID()
        record.startAt = Calendar.current.date(byAdding: .hour, value: -8, to: Date())!
        record.endAt = Date()
        record.quality = 4
        record.score = 85
        record.debt = 1.5
        
        let record2 = SleepRecord(context: context)
        record2.id = UUID()
        record2.startAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        record2.endAt = Calendar.current.date(byAdding: .hour, value: 7, to: record2.startAt!)!
        record2.quality = 3
        record2.score = 65
        record2.debt = 2.0
        
        return ScrollView {
            VStack(spacing: 12) {
                SleepRecordCard(record: record)
                SleepRecordCard(record: record2)
            }
            .padding()
        }
        .background(Theme.Colors.background)
    }
} 