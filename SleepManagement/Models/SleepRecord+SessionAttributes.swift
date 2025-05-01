import Foundation
import CoreData

extension SleepRecord {
    @NSManaged public var totalInBedTime: Double
    @NSManaged public var totalAsleepTime: Double
    @NSManaged public var totalAwakeTime: Double
    @NSManaged public var sleepLatency: Double
    @NSManaged public var sleepEfficiency: Double
    @NSManaged public var isNap: Bool
} 