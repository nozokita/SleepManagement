import SwiftUI

struct SleepRecordDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let record: SleepRecord
    @State private var showingEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // スコア表示
                VStack(spacing: 8) {
                    // 仮眠の場合はNapラベルを表示
                    if SleepRecordType(rawValue: record.sleepType) == .nap {
                        ZStack {
                            Circle()
                                .stroke(Theme.Colors.subtext, lineWidth: 1)
                                .frame(width: 150, height: 150)
                            Text("nap".localized)
                                .font(Theme.Typography.subheadingFont)
                                .foregroundColor(Theme.Colors.subtext)
                        }
                        Text("nap".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.subtext)
                    } else {
                        SleepScoreView(score: record.score, size: 150)
                        Text("sleep_score".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.subtext)
                    }
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
                            title: "sleep_debt".localized,
                            value: record.debtText,
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
                
                // 編集ボタン
                Button(action: {
                    showingEditSheet = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                            .font(.headline)
                        
                        Text("記録を編集")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.primaryGradient)
                    .cornerRadius(12)
                    .shadow(color: Theme.Colors.primary.opacity(0.4), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
            .padding()
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("睡眠詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // レコード削除ボタン
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    viewContext.delete(record)
                    do {
                        try viewContext.save()
                    } catch {
                        print("削除エラー: \(error)")
                    }
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditSleepRecordView(record: record)
                .environment(\.managedObjectContext, viewContext)
        }
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
                .environment(\.managedObjectContext, context)
        }
    }
} 