import SwiftData

@Model
struct UserSettings {
    var id: UUID = UUID()
    var birthYear: Int = Calendar.current.component(.year, from: Date())
    var idealSleepDuration: TimeInterval = 8 * 3600
} 