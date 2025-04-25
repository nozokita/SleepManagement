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

    private init() {
        let storedYear = UserDefaults.standard.integer(forKey: "birthYear")
        self.birthYear = storedYear != 0 ? storedYear : Calendar.current.component(.year, from: Date())

        let storedDuration = UserDefaults.standard.double(forKey: "idealSleepDuration")
        self.idealSleepDuration = storedDuration != 0 ? storedDuration : 8 * 3600
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
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
} 