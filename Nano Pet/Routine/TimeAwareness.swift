//
//  TimeAwareness.swift
//  Nano Pet
//
//  Time-of-day detection for contextual routine selection.
//

import Foundation

// MARK: - Time of Day

/// Represents different periods of the day
enum TimeOfDay: String, CaseIterable {
    case earlyMorning   // 5:00 - 8:00   Wake up period
    case morning        // 8:00 - 12:00  Active period
    case afternoon      // 12:00 - 14:00 Siesta period
    case lateAfternoon  // 14:00 - 18:00 Active period
    case evening        // 18:00 - 22:00 Relaxation period
    case night          // 22:00 - 5:00  Sleep period

    /// Human-readable description
    var description: String {
        switch self {
        case .earlyMorning: return "Early Morning (5-8)"
        case .morning: return "Morning (8-12)"
        case .afternoon: return "Afternoon (12-14)"
        case .lateAfternoon: return "Late Afternoon (14-18)"
        case .evening: return "Evening (18-22)"
        case .night: return "Night (22-5)"
        }
    }

    /// Whether this is a typically active period
    var isActivePeriod: Bool {
        switch self {
        case .morning, .lateAfternoon:
            return true
        case .earlyMorning, .afternoon, .evening, .night:
            return false
        }
    }

    /// Whether this is a rest period
    var isRestPeriod: Bool {
        switch self {
        case .afternoon, .night:
            return true
        case .earlyMorning, .morning, .lateAfternoon, .evening:
            return false
        }
    }
}

// MARK: - Time Awareness

/// Utility for detecting current time of day
enum TimeAwareness {
    /// Get the current time of day
    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        return timeOfDay(forHour: hour)
    }

    /// Get time of day for a specific hour (0-23)
    static func timeOfDay(forHour hour: Int) -> TimeOfDay {
        switch hour {
        case 5..<8:
            return .earlyMorning
        case 8..<12:
            return .morning
        case 12..<14:
            return .afternoon
        case 14..<18:
            return .lateAfternoon
        case 18..<22:
            return .evening
        default:
            return .night  // 22-5
        }
    }

    /// Check if current time matches a specific period
    static func isCurrently(_ period: TimeOfDay) -> Bool {
        current == period
    }

    /// Check if current time is one of multiple periods
    static func isCurrentlyOneOf(_ periods: [TimeOfDay]) -> Bool {
        periods.contains(current)
    }

    /// Get the next time period after current
    static var nextPeriod: TimeOfDay {
        let allCases = TimeOfDay.allCases
        guard let currentIndex = allCases.firstIndex(of: current) else {
            return .earlyMorning
        }
        let nextIndex = (currentIndex + 1) % allCases.count
        return allCases[nextIndex]
    }
}
