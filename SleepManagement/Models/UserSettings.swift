import SwiftData
import Foundation

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var birthYear: Int
    var idealSleepDuration: TimeInterval

    init(
        id: UUID = UUID(),
        birthYear: Int = Calendar.current.component(.year, from: Date()),
        idealSleepDuration: TimeInterval = 8 * 3600
    ) {
        self.id = id
        self.birthYear = birthYear
        self.idealSleepDuration = idealSleepDuration
    }
} 