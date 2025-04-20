import SwiftUI

struct SleepRecordDetailView: View {
    let record: SleepRecord
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // スコア表示
                VStack(spacing: 8) {
                    SleepScoreView(score: record.score, size: 150)
                    
                    Text("睡眠スコア")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.subtext)
                }
                .padding(.vertical, 16)
                
                // 詳細情報
                VStack(spacing: 16) {
                    detailRow(title: "日付", value: record.sleepDateText, icon: "calendar")
                    
                    detailRow(title: "睡眠時間", value: "\(record.startTimeText) - \(record.endTimeText)", icon: "clock")
                    
                    detailRow(title: "睡眠の長さ", value: record.durationText, icon: "bed.double")
                    
                    detailRow(title: "睡眠の質", value: "\(record.quality)/5", icon: "star")
                    
                    if record.debt > 0 {
                        detailRow(
                            title: "睡眠負債", 
                            value: String(format: "%.1f時間", record.debt),
                            icon: "exclamationmark.triangle",
                            color: Theme.Colors.scoreColor(score: max(0, 100 - record.debt * 10))
                        )
                    }
                }
                .padding()
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.Layout.cardCornerRadius)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // メモがあれば表示
                if let memo = record.memo, !memo.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(Theme.Colors.primary)
                            Text("メモ")
                                .font(Theme.Typography.subheadingFont)
                                .foregroundColor(Theme.Colors.text)
                        }
                        
                        Text(memo)
                            .font(Theme.Typography.bodyFont)
                            .foregroundColor(Theme.Colors.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.Layout.cardCornerRadius)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("睡眠詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func detailRow(title: String, value: String, icon: String, color: Color = Theme.Colors.text) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 24)
            
            Text(title)
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            Text(value)
                .font(Theme.Typography.bodyFont.bold())
                .foregroundColor(color)
        }
    }
}

// プレビュー用のダミーレコード
private struct SleepRecordDetailPreview: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let record = SleepRecord(context: context)
        record.id = UUID()
        record.startAt = Calendar.current.date(byAdding: .hour, value: -8, to: Date())!
        record.endAt = Date()
        record.quality = 4
        record.score = 85
        record.debt = 1.5
        record.memo = "昨夜は早めに就寝したので、朝の目覚めがすっきりしていました。カフェインを控えたのも良かったかもしれません。"
        
        return NavigationView {
            SleepRecordDetailView(record: record)
        }
    }
} 