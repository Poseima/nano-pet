//
//  RoutineEngine.swift
//  Nano Pet
//
//  Scheduling engine for managing active routines.
//  Coordinates routine execution and state transitions.
//

import Foundation
import CoreGraphics

// MARK: - Routine Engine

/// Engine for managing and executing routines
final class RoutineEngine {

    // MARK: - Properties

    /// Currently active routine (nil if none)
    private(set) var activeRoutine: (any Routine)?

    /// Name of the last completed state (for routine step tracking)
    private var lastStateName: String = ""

    /// Tick count when current routine started
    private var routineStartTick: UInt64 = 0

    /// Tick count when current step started
    private var stepStartTick: UInt64 = 0

    /// Registry for available routines
    weak var registry: RoutineRegistry?

    /// Pet identifier for logging
    var petIdentifier: String = "Unknown"

    // MARK: - State Tracking

    /// Whether a routine is currently active
    var hasActiveRoutine: Bool {
        activeRoutine != nil
    }

    /// Name of the active routine (or empty string)
    var activeRoutineName: String {
        activeRoutine?.name ?? ""
    }

    // MARK: - Routine Control

    /// Start executing a routine
    /// - Parameters:
    ///   - routine: The routine to start
    ///   - context: Current context
    /// - Returns: The first state to execute
    func startRoutine(_ routine: any Routine, context: RoutineContext) -> any PetState {
        // Cancel any existing routine
        if let current = activeRoutine {
            current.finish(completed: false, context: context)
            print("[RoutineEngine] [\(petIdentifier)] Canceling \(current.name) to start \(routine.name)")
        }

        activeRoutine = routine
        routine.reset()
        routineStartTick = context.currentTick
        stepStartTick = context.currentTick

        let firstState = routine.start(context: context)
        lastStateName = firstState.name

        print("[RoutineEngine] [\(petIdentifier)] Started routine: \(routine.name) (\(routine.emotion))")

        return firstState
    }

    // Bug #2 fix: onStateComplete() was dead code - removed
    // The tick() method already handles routine step advancement

    /// Notify engine that a tick has passed (for duration tracking)
    /// - Parameters:
    ///   - stateName: Current state name
    ///   - context: Current context
    /// - Returns: Next state if routine wants to transition, nil otherwise
    func tick(stateName: String, context: RoutineContext) -> (any PetState)? {
        guard let routine = activeRoutine else { return nil }

        // Let routine check if it's time to advance (using new unambiguous result type)
        let result = routine.nextStep(afterState: stateName, context: context)

        switch result {
        case .continueCurrentStep:
            // Stay in current state, no action needed
            return nil

        case .advanceToState(let nextState):
            // Advance to the next state
            lastStateName = nextState.name
            stepStartTick = context.currentTick
            return nextState

        case .routineComplete:
            // Routine is done
            finishRoutine(completed: true, context: context)
            return nil
        }
    }

    /// Cancel the current routine
    func cancelRoutine(context: RoutineContext? = nil) {
        guard let routine = activeRoutine else { return }

        let ctx = context ?? RoutineContext(
            currentTick: 0,
            position: .zero,
            perception: nil,
            timeOfDay: TimeAwareness.current
        )

        routine.finish(completed: false, context: ctx)
        print("[RoutineEngine] [\(petIdentifier)] Cancelled routine: \(routine.name)")

        activeRoutine = nil
        lastStateName = ""
    }

    /// Force finish the current routine
    /// Bug #8 fix: Guard ensures this can only be called once per routine
    private func finishRoutine(completed: Bool, context: RoutineContext) {
        guard let routine = activeRoutine else {
            // Already finished or no active routine - prevent double completion
            return
        }

        // Clear activeRoutine BEFORE calling finish to prevent re-entrant calls
        activeRoutine = nil
        lastStateName = ""

        routine.finish(completed: completed, context: context)
        print("[RoutineEngine] [\(petIdentifier)] Finished routine: \(routine.name) (completed: \(completed))")
    }

    // MARK: - Interrupt Handling

    /// Check if current routine can be interrupted by a new routine
    /// - Parameter newRoutine: The routine that wants to interrupt
    /// - Returns: True if interruption is allowed
    func canInterrupt(by newRoutine: any Routine) -> Bool {
        guard let current = activeRoutine else { return true }

        // Higher priority can always interrupt
        if newRoutine.priority > current.priority {
            return true
        }

        // Same or lower priority can only interrupt if current is interruptible
        return current.isInterruptible
    }

    /// Check if routine can be interrupted by user action (dragging, etc.)
    var canBeInterruptedByUser: Bool {
        guard let current = activeRoutine else { return true }
        return current.isInterruptible
    }

    // MARK: - Random Routine Selection

    /// Select and start a random routine appropriate for current time
    /// - Parameter context: Current context
    /// - Returns: First state of selected routine, or nil if no routine selected
    func startRandomRoutine(context: RoutineContext) -> (any PetState)? {
        guard let registry = registry else {
            print("[RoutineEngine] [\(petIdentifier)] No registry available")
            return nil
        }

        guard let routine = registry.selectRoutine(for: context.timeOfDay) else {
            print("[RoutineEngine] [\(petIdentifier)] No suitable routine found for \(context.timeOfDay)")
            return nil
        }

        return startRoutine(routine, context: context)
    }

    // MARK: - Debug

    /// Get debug description of current state
    var debugDescription: String {
        if let routine = activeRoutine {
            return "Routine: \(routine.name), LastState: \(lastStateName)"
        }
        return "No active routine"
    }
}
