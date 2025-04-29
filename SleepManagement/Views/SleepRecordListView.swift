import SwiftUI
import CoreData

/// 直近30日間の全睡眠記録を一覧表示する画面
struct SleepRecordListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var records: [SleepRecord] = []
    // 編集用状態
    @State private var selectedRecordForEdit: SleepRecord? = nil
    @State private var showListScoreInfo = false

    var body: some View {
        List {
            if records.isEmpty {
                Text("no_records".localized)
                    .foregroundColor(.secondary)
            } else {
                ForEach(records, id: \.id) { record in
                    NavigationLink(destination: SleepRecordDetailView(record: record)
                                    .environment(\.managedObjectContext, viewContext)) {
                        SleepRecordCard(record: record)
                    }
                    .swipeActions(edge: .trailing) {
                        // 編集
                        Button {
                            selectedRecordForEdit = record
                        } label: {
                            Label("list.edit".localized, systemImage: "pencil")
                        }
                        .tint(.blue)
                        // 削除
                        Button(role: .destructive) {
                            deleteRecord(record)
                        } label: {
                            Label("list.delete".localized, systemImage: "trash")
                        }
                    }
                }
            }
        }
        // 編集シート
        .sheet(item: $selectedRecordForEdit) { record in
            EditSleepRecordView(record: record)
                .environment(\.managedObjectContext, viewContext)
        }
        .navigationTitle("sleep_record_list_title".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showListScoreInfo = true }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .alert("score_info_title".localized, isPresented: $showListScoreInfo) {
            Button("common.okButton".localized, role: .cancel) {}
        } message: {
            Text("manual_score_info_message".localized)
        }
        .onAppear(perform: loadRecords)
    }

    /// 直近30日分のSleepRecordをCoreDataから取得
    private func loadRecords() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let pastDate = calendar.date(byAdding: .day, value: -29, to: today) else {
            records = []
            return
        }
        let request: NSFetchRequest<SleepRecord> = SleepRecord.createFetchRequest()
        request.predicate = NSPredicate(format: "startAt >= %@", pastDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SleepRecord.startAt, ascending: false)]
        do {
            records = try viewContext.fetch(request)
        } catch {
            print("30日間の睡眠記録取得失敗: \(error)")
            records = []
        }
    }

    // レコードを削除
    private func deleteRecord(_ record: SleepRecord) {
        viewContext.delete(record)
        do {
            try viewContext.save()
            loadRecords()
        } catch {
            print("睡眠記録削除エラー: \(error)")
        }
    }
} 