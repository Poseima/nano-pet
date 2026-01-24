//
//  RoutineRegistry.swift
//  Nano Pet
//
//  Registry for available routines with time-based selection.
//

import Foundation

// MARK: - Routine Weight

/// Weight configuration for routine selection
struct RoutineWeight {
    let routineFactory: () -> any Routine
    let weight: Int

    /// Initialize with a closure that creates a fresh routine instance each time
    init(routineFactory: @escaping () -> any Routine, weight: Int) {
        self.routineFactory = routineFactory
        self.weight = weight
    }
}

// MARK: - Time Period Routines

/// Routines available for a specific time period
struct TimePeriodRoutines {
    /// High probability routines (weighted more heavily)
    var highPriority: [RoutineWeight] = []

    /// Medium probability routines
    var mediumPriority: [RoutineWeight] = []

    /// Low probability routines
    var lowPriority: [RoutineWeight] = []

    /// All routines available for this period
    var allRoutines: [RoutineWeight] {
        highPriority + mediumPriority + lowPriority
    }

    /// Select a weighted random routine
    func selectRandom() -> (any Routine)? {
        // Calculate total weight with priority multipliers
        // High priority: weight * 3, Medium: weight * 2, Low: weight * 1
        var weightedChoices: [(routine: () -> any Routine, weight: Int)] = []

        for r in highPriority {
            weightedChoices.append((r.routineFactory, r.weight * 3))
        }
        for r in mediumPriority {
            weightedChoices.append((r.routineFactory, r.weight * 2))
        }
        for r in lowPriority {
            weightedChoices.append((r.routineFactory, r.weight))
        }

        guard !weightedChoices.isEmpty else { return nil }

        let totalWeight = weightedChoices.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return nil }

        var roll = Int.random(in: 0..<totalWeight)

        for choice in weightedChoices {
            roll -= choice.weight
            if roll < 0 {
                return choice.routine()
            }
        }

        // Fallback: return first routine
        return weightedChoices.first?.routine()
    }
}

// MARK: - Routine Registry

/// Central registry for all available routines
final class RoutineRegistry {

    // MARK: - Singleton

    static let shared = RoutineRegistry()

    // MARK: - Properties

    /// Routines organized by time period
    private var routinesByPeriod: [TimeOfDay: TimePeriodRoutines] = [:]

    /// Universal routines (available at all times)
    private var universalRoutines: [RoutineWeight] = []

    // MARK: - Initialization

    private init() {
        setupDefaultRoutines()
    }

    // MARK: - Registration

    /// Register a routine for specific time periods
    func register(_ routineFactory: @escaping () -> any Routine,
                  weight: Int = 10,
                  priority: RoutinePriority = .normal,
                  for periods: [TimeOfDay]) {
        let routineWeight = RoutineWeight(routineFactory: routineFactory, weight: weight)

        for period in periods {
            if routinesByPeriod[period] == nil {
                routinesByPeriod[period] = TimePeriodRoutines()
            }

            // Bug #4 fix: background goes to lowPriority, not mediumPriority
            switch priority {
            case .background:
                routinesByPeriod[period]?.lowPriority.append(routineWeight)
            case .normal:
                routinesByPeriod[period]?.mediumPriority.append(routineWeight)
            case .focused, .scripted:
                routinesByPeriod[period]?.highPriority.append(routineWeight)
            }
        }
    }

    /// Register a routine as high priority for specific time periods
    func registerHighPriority(_ routineFactory: @escaping () -> any Routine,
                              weight: Int = 10,
                              for periods: [TimeOfDay]) {
        let routineWeight = RoutineWeight(routineFactory: routineFactory, weight: weight)

        for period in periods {
            if routinesByPeriod[period] == nil {
                routinesByPeriod[period] = TimePeriodRoutines()
            }
            routinesByPeriod[period]?.highPriority.append(routineWeight)
        }
    }

    /// Register a routine as low priority for specific time periods
    func registerLowPriority(_ routineFactory: @escaping () -> any Routine,
                             weight: Int = 5,
                             for periods: [TimeOfDay]) {
        let routineWeight = RoutineWeight(routineFactory: routineFactory, weight: weight)

        for period in periods {
            if routinesByPeriod[period] == nil {
                routinesByPeriod[period] = TimePeriodRoutines()
            }
            routinesByPeriod[period]?.lowPriority.append(routineWeight)
        }
    }

    /// Register a universal routine (available at all times)
    func registerUniversal(_ routineFactory: @escaping () -> any Routine,
                           weight: Int = 5) {
        let routineWeight = RoutineWeight(routineFactory: routineFactory, weight: weight)
        universalRoutines.append(routineWeight)
    }

    // MARK: - Selection

    /// Select a random routine appropriate for the given time of day
    func selectRoutine(for timeOfDay: TimeOfDay) -> (any Routine)? {
        // Get period-specific routines
        let periodRoutines = routinesByPeriod[timeOfDay] ?? TimePeriodRoutines()

        // Combine with universal routines (as low priority)
        var combined = periodRoutines
        combined.lowPriority.append(contentsOf: universalRoutines)

        return combined.selectRandom()
    }

    /// Get all routines available for a time period
    func routines(for timeOfDay: TimeOfDay) -> [any Routine] {
        guard let periodRoutines = routinesByPeriod[timeOfDay] else { return [] }
        return periodRoutines.allRoutines.map { $0.routineFactory() }
    }

    // MARK: - Default Setup

    private func setupDefaultRoutines() {
        // ===== Early Morning (5:00 - 8:00) =====
        registerHighPriority({ MorningStretchRoutine() }, weight: 20, for: [.earlyMorning])
        registerHighPriority({ ExerciseRoutine() }, weight: 15, for: [.earlyMorning])

        // ===== Morning (8:00 - 12:00) =====
        register({ ForagingRoutine() }, weight: 10, for: [.morning, .lateAfternoon])
        register({ ExerciseRoutine() }, weight: 10, for: [.morning])

        // ===== Afternoon (12:00 - 14:00) =====
        registerHighPriority({ NapRoutine() }, weight: 20, for: [.afternoon])
        registerHighPriority({ SunbathingRoutine() }, weight: 15, for: [.afternoon])

        // ===== Late Afternoon (14:00 - 18:00) =====
        register({ ForagingRoutine() }, weight: 10, for: [.lateAfternoon])

        // ===== Evening (18:00 - 22:00) =====
        register({ NapRoutine() }, weight: 10, for: [.evening])

        // ===== Night (22:00 - 5:00) =====
        registerHighPriority({ DeepSleepRoutine() }, weight: 25, for: [.night])
        registerHighPriority({ NightPatrolRoutine() }, weight: 15, for: [.night])

        // ===== Universal (low priority, all times) =====
        registerUniversal({ ForagingRoutine() }, weight: 5)
    }

    // MARK: - Debug

    /// Get a summary of registered routines
    var summary: String {
        var lines: [String] = ["Routine Registry:"]

        for period in TimeOfDay.allCases {
            guard let routines = routinesByPeriod[period] else { continue }
            let count = routines.allRoutines.count
            if count > 0 {
                lines.append("  \(period.description): \(count) routines")
            }
        }

        lines.append("  Universal: \(universalRoutines.count) routines")
        return lines.joined(separator: "\n")
    }
}
