import Foundation
import Combine

/// ユーザーのクロノタイプ
enum Chronotype: Int, CaseIterable {
    case morning    // 朝型
    case neutral    // 中間型
    case evening    // 夜型

    /// 表示用テキスト (ローカライズ)
    var displayName: String {
        switch self {
        case .morning: return "chronotype_morning".localized
        case .neutral: return "chronotype_neutral".localized
        case .evening: return "chronotype_evening".localized
        }
    }
}

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
    /// 睡眠セッションの区切り時間（秒）
    @Published var sleepGapThreshold: TimeInterval = 30 * 60
    @Published var chronotype: Chronotype = .neutral

    private init() {
        let storedYear = UserDefaults.standard.integer(forKey: "birthYear")
        self.birthYear = storedYear != 0 ? storedYear : Calendar.current.component(.year, from: Date())

        let storedDuration = UserDefaults.standard.double(forKey: "idealSleepDuration")
        self.idealSleepDuration = storedDuration != 0 ? storedDuration : 8 * 3600
        // 短い睡眠判別設定の読み込み
        self.treatShortSleepAsNap = UserDefaults.standard.bool(forKey: "treatShortSleepAsNap")
        let storedThreshold = UserDefaults.standard.double(forKey: "shortSleepThreshold")
        self.shortSleepThreshold = storedThreshold != 0 ? storedThreshold : 90 * 60
        // 睡眠セッションの区切り時間の読み込み
        let storedGapThreshold = UserDefaults.standard.double(forKey: "sleepGapThreshold")
        self.sleepGapThreshold = storedGapThreshold != 0 ? storedGapThreshold : 30 * 60
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
        let storedChrono = UserDefaults.standard.integer(forKey: "chronotype")
        self.chronotype = Chronotype(rawValue: storedChrono) ?? .neutral
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
        UserDefaults.standard.set(sleepGapThreshold, forKey: "sleepGapThreshold")
        UserDefaults.standard.set(chronotype.rawValue, forKey: "chronotype")
    }

    /// クロノタイプを数値化 (Morning=0.0, Neutral=0.5, Evening=1.0)
    var chronotypeValue: Double {
        switch chronotype {
        case .morning: return 0.0
        case .neutral: return 0.5
        case .evening: return 1.0
        }
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
} 