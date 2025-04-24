import Foundation
import Combine

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var birthYear: Int
    @Published var idealSleepDuration: TimeInterval

    private init() {
        let storedYear = UserDefaults.standard.integer(forKey: "birthYear")
        self.birthYear = storedYear != 0 ? storedYear : Calendar.current.component(.year, from: Date())

        let storedDuration = UserDefaults.standard.double(forKey: "idealSleepDuration")
        self.idealSleepDuration = storedDuration != 0 ? storedDuration : 8 * 3600
    }

    func save() {
        UserDefaults.standard.set(birthYear, forKey: "birthYear")
        UserDefaults.standard.set(idealSleepDuration, forKey: "idealSleepDuration")
    }
} 