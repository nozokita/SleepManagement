import SwiftUI
import CoreData
import Combine

struct SleepInputView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var sleepStart: Date = Date().addingTimeInterval(-8 * 3600) // 初期就寝日時(8時間前)
    @State private var sleepEnd: Date = Date()                        // 初期起床日時(現在)
    @State private var quality: Double = 3
    @State private var selectedSleepType: SleepRecordType = .normalSleep
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // ヘッダー表示
                    headerView
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                    
                    // 入力フォーム
                    manualInputForm
                        .padding(.bottom, 85) // 保存ボタンの高さ分空ける
                    
                    Spacer(minLength: 0)
                }
                
                // 保存ボタン（下部に固定）
                VStack {
                    Spacer()
                    
                    Button(action: saveSleepRecord) {
                        Text("save".localized)
                            .font(Theme.Typography.bodyFont.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.Colors.primaryGradient)
                            .cornerRadius(12)
                            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .background(
                        Rectangle()
                            .fill(Theme.Colors.background)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -3)
                            .edgesIgnoringSafeArea(.bottom)
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("cancel".localized)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("sleep_input_title".localized)
                        .font(Theme.Typography.titleFont)
                        .foregroundColor(Theme.Colors.text)
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // ヘッダー
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("sleep_record_instruction".localized)
                .font(Theme.Typography.subheadingFont)
                .foregroundColor(Theme.Colors.text)
            
            Text("sleep_input_description".localized)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.subtext)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // 手動入力フォーム (就寝開始日時と起床日時を別々に入力)
    private var manualInputForm: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 睡眠タイプセクション
                VStack(alignment: .leading, spacing: 10) {
                    Text("sleep_type".localized)
                        .font(Theme.Typography.subheadingFont)
                        .foregroundColor(Theme.Colors.text)
                    HStack(spacing: 12) {
                        ForEach(SleepRecordType.allCases, id: \.self) { type in
                            Button(action: {
                                selectedSleepType = type
                            }) {
                                HStack {
                                    Image(systemName: type.iconName)
                                        .foregroundColor(selectedSleepType == type ? .white : Theme.Colors.primary)
                                    Text(type.displayName)
                                        .font(Theme.Typography.bodyFont)
                                        .foregroundColor(selectedSleepType == type ? .white : Theme.Colors.primary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedSleepType == type ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.1))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.5))
                )
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2)
                .padding(.bottom, 8)
                
                // 就寝開始日時
                VStack(alignment: .leading, spacing: 6) {
                    Text("sleep_start_datetime".localized)
                        .font(Theme.Typography.subheadingFont)
                        .foregroundColor(Theme.Colors.text)
                    DatePicker("", selection: $sleepStart, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Theme.Colors.cardBackground)
                        )
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.5))
                )
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2)
                .padding(.bottom, 8)
                
                // 起床日時
                VStack(alignment: .leading, spacing: 6) {
                    Text("wake_datetime".localized)
                        .font(Theme.Typography.subheadingFont)
                        .foregroundColor(Theme.Colors.text)
                    DatePicker("", selection: $sleepEnd, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Theme.Colors.cardBackground)
                        )
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.5))
                )
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2)
                .padding(.bottom, 8)
                
                // 睡眠時間表示
                HStack {
                    Spacer()
                    Text(sleepDurationText)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.primary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Theme.Colors.primary.opacity(0.1))
                        .cornerRadius(8)
                }
                // 睡眠の質入力
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("sleep_quality".localized)
                            .font(Theme.Typography.subheadingFont)
                            .foregroundColor(Theme.Colors.text)
                        Spacer()
                        Text("\(Int(quality))" + "points".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Theme.Colors.primary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.top, 5)
                    Slider(value: $quality, in: 1...5, step: 1)
                        .accentColor(Theme.Colors.primary)
                    HStack {
                        Text("poor".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.subtext)
                        Spacer()
                        Text("excellent".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.subtext)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.5))
                )
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2)
                .padding(.bottom, 8)
            }
            .padding(.vertical, 8)
        }
    }
    
    // 睡眠時間テキスト
    private var sleepDurationText: String {
        let duration = sleepEnd.timeIntervalSince(sleepStart)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "sleep_duration".localized + " \(hours)" + "hours".localized + " \(minutes)" + "minutes".localized
    }
    
    // 睡眠記録の保存
    private func saveSleepRecord() {
        // 入力検証：起床時間が就寝時間より後か
        if sleepEnd <= sleepStart {
            alertTitle = "error_invalid_time_title".localized
            alertMessage = "error_invalid_time_message".localized
            showingAlert = true
            return
        }
        let sleepManager = SleepManager.shared
        let _ = sleepManager.addSleepRecord(
            context: viewContext,
            startAt: sleepStart,
            endAt: sleepEnd,
            quality: Int16(quality),
            sleepType: selectedSleepType,
            memo: nil
        )
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    SleepInputView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(LocalizationManager.shared)
} 