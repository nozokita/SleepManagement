import Foundation
import Combine

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var birthYear: Int
    @Published var idealSleepDuration: TimeInterval
    @Published var enableSleepReminder: Bool = false
    @Published var sleepReminderTime: Date = Date()
    @Published var enableMorningSummary: Bool = false
    @Published var morningSummaryTime: Date = Date()
    @Published var useSystemTheme: Bool = true
    @Published var darkModeEnabled: Bool = false
    @Published var showSleepDebt: Bool = true
    @Published var showSleepScore: Bool = true
    @Published var autoSyncHealthKit: Bool = false
    /// HealthKit同期時に短い睡眠を仮眠扱いにする
    @Published var treatShortSleepAsNap: Bool = false
    /// 短い睡眠とみなす閾値（秒）
    @Published var shortSleepThreshold: TimeInterval = 90 * 60

    private init() {
        let storedYear = UserDefaults.standard.integer(forKey: "birthYear")
        self.birthYear = storedYear != 0 ? storedYear : Calendar.current.component(.year, from: Date())

        let storedDuration = UserDefaults.standard.double(forKey: "idealSleepDuration")
        self.idealSleepDuration = storedDuration != 0 ? storedDuration : 8 * 3600
        // 短い睡眠判別設定の読み込み
        self.treatShortSleepAsNap = UserDefaults.standard.bool(forKey: "treatShortSleepAsNap")
        let storedThreshold = UserDefaults.standard.double(forKey: "shortSleepThreshold")
        self.shortSleepThreshold = storedThreshold != 0 ? storedThreshold : 90 * 60
        // その他の設定の読み込み
        self.autoSyncHealthKit = UserDefaults.standard.bool(forKey: "autoSyncHealthKit")
        self.enableSleepReminder = UserDefaults.standard.bool(forKey: "enableSleepReminder")
        self.sleepReminderTime = UserDefaults.standard.object(forKey: "sleepReminderTime") as? Date ?? self.sleepReminderTime
        self.enableMorningSummary = UserDefaults.standard.bool(forKey: "enableMorningSummary")
        self.morningSummaryTime = UserDefaults.standard.object(forKey: "morningSummaryTime") as? Date ?? self.morningSummaryTime
        self.useSystemTheme = UserDefaults.standard.bool(forKey: "useSystemTheme")
        self.darkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")
        self.showSleepDebt = UserDefaults.standard.bool(forKey: "showSleepDebt")
        self.showSleepScore = UserDefaults.standard.bool(forKey: "showSleepScore")
    }

    func save() {
        UserDefaults.standard.set(birthYear, forKey: "birthYear")
        UserDefaults.standard.set(idealSleepDuration, forKey: "idealSleepDuration")
        UserDefaults.standard.set(enableSleepReminder, forKey: "enableSleepReminder")
        UserDefaults.standard.set(sleepReminderTime, forKey: "sleepReminderTime")
        UserDefaults.standard.set(enableMorningSummary, forKey: "enableMorningSummary")
        UserDefaults.standard.set(morningSummaryTime, forKey: "morningSummaryTime")
        UserDefaults.standard.set(useSystemTheme, forKey: "useSystemTheme")
        UserDefaults.standard.set(darkModeEnabled, forKey: "darkModeEnabled")
        UserDefaults.standard.set(showSleepDebt, forKey: "showSleepDebt")
        UserDefaults.standard.set(showSleepScore, forKey: "showSleepScore")
        UserDefaults.standard.set(autoSyncHealthKit, forKey: "autoSyncHealthKit")
        UserDefaults.standard.set(treatShortSleepAsNap, forKey: "treatShortSleepAsNap")
        UserDefaults.standard.set(shortSleepThreshold, forKey: "shortSleepThreshold")
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
} 