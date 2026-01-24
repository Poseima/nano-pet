//
//  RoutineProtocol.swift
//  Nano Pet
//
//  Protocol and types for routine behavior sequences.
//  Routines orchestrate multiple states into coherent behavioral narratives.
//

import Foundation
import CoreGraphics

// MARK: - Routine Priority

/// Priority levels for routines
enum RoutinePriority: Int, Comparable {
    case background = 0    // Background routine, can be interrupted anytime
    case normal = 1        // Normal routine
    case focused = 2       // Focused routine, hard to interrupt
    case scripted = 3      // Scripted routine, must complete

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Routine Step

/// A single step in a routine
struct RoutineStep {
    /// The state to execute
    let stateFactory: () -> any PetState

    /// Duration in ticks (60 ticks = 1 second)
    let duration: UInt64

    /// Description for debugging
    let description: String

    /// Create a step with a state factory and duration
    init(state: @escaping @autoclosure () -> any PetState, duration: UInt64, description: String = "") {
        self.stateFactory = state
        self.duration = duration
        self.description = description
    }
}

// MARK: - Routine Step Result

/// Result from nextStep() to clearly distinguish between different outcomes
enum RoutineStepResult {
    /// Continue executing current step (no state change)
    case continueCurrentStep

    /// Advance to the next state
    case advanceToState(any PetState)

    /// Routine is complete
    case routineComplete
}

// MARK: - Routine Context

/// Context provided to routines for decision making
struct RoutineContext {
    let currentTick: UInt64
    let position: CGPoint
    let perception: Perception?
    let timeOfDay: TimeOfDay

    static func current(tick: UInt64, position: CGPoint, perception: Perception?) -> RoutineContext {
        RoutineContext(
            currentTick: tick,
            position: position,
            perception: perception,
            timeOfDay: TimeAwareness.current
        )
    }
}

// MARK: - Routine Protocol

/// Protocol for behavior routines that orchestrate multiple states
protocol Routine: AnyObject {
    /// Name of the routine
    var name: String { get }

    /// Priority of this routine
    var priority: RoutinePriority { get }

    /// Whether this routine can be interrupted by user actions (like dragging)
    var isInterruptible: Bool { get }

    /// Emotional description of this routine
    var emotion: String { get }

    /// Total duration estimate in ticks
    var estimatedDuration: UInt64 { get }

    /// Called when the routine starts, returns the first state
    func start(context: RoutineContext) -> any PetState

    /// Called each tick to check if routine should advance
    /// - Returns: RoutineStepResult indicating continue, advance, or complete
    func nextStep(afterState: String, context: RoutineContext) -> RoutineStepResult

    /// Called when the routine ends (either completed or interrupted)
    func finish(completed: Bool, context: RoutineContext)

    /// Reset the routine for reuse
    func reset()
}

// MARK: - Default Implementations

extension Routine {
    var priority: RoutinePriority { .normal }
    var isInterruptible: Bool { true }
    var emotion: String { "" }

    func finish(completed: Bool, context: RoutineContext) {}
    func reset() {}
}

// MARK: - Linear Routine Base Class

/// Base class for simple linear routines (execute steps in sequence)
class LinearRoutine: Routine {
    let name: String
    let priority: RoutinePriority
    let isInterruptible: Bool
    let emotion: String

    /// Steps to execute in order
    let steps: [RoutineStep]

    /// Current step index
    private(set) var currentStepIndex: Int = 0

    /// Ticks spent in current step
    private(set) var ticksInCurrentStep: UInt64 = 0

    /// Whether the current step's state has been created
    private var currentStateCreated: Bool = false

    var estimatedDuration: UInt64 {
        steps.reduce(0) { $0 + $1.duration }
    }

    init(name: String,
         priority: RoutinePriority = .normal,
         isInterruptible: Bool = true,
         emotion: String = "",
         steps: [RoutineStep]) {
        self.name = name
        self.priority = priority
        self.isInterruptible = isInterruptible
        self.emotion = emotion
        self.steps = steps
    }

    func start(context: RoutineContext) -> any PetState {
        // Bug #7 fix: Guard against empty steps array
        precondition(!steps.isEmpty, "LinearRoutine '\(name)' must have at least one step")

        currentStepIndex = 0
        ticksInCurrentStep = 0
        currentStateCreated = true
        print("[Routine] Starting \(name): \(emotion)")
        return steps[0].stateFactory()
    }

    func nextStep(afterState: String, context: RoutineContext) -> RoutineStepResult {
        ticksInCurrentStep += 1

        // Check if we've already completed all steps
        guard currentStepIndex < steps.count else { return .routineComplete }

        let currentStep = steps[currentStepIndex]
        if ticksInCurrentStep >= currentStep.duration {
            // Move to next step
            currentStepIndex += 1
            ticksInCurrentStep = 0

            if currentStepIndex < steps.count {
                let nextStep = steps[currentStepIndex]
                print("[Routine] \(name) step \(currentStepIndex + 1)/\(steps.count): \(nextStep.description)")
                return .advanceToState(nextStep.stateFactory())
            } else {
                // Routine complete
                return .routineComplete
            }
        }

        // Continue with current step (no state change needed)
        return .continueCurrentStep
    }

    func finish(completed: Bool, context: RoutineContext) {
        let status = completed ? "completed" : "interrupted"
        print("[Routine] \(name) \(status) at step \(currentStepIndex + 1)/\(steps.count)")
    }

    func reset() {
        currentStepIndex = 0
        ticksInCurrentStep = 0
        currentStateCreated = false
    }
}
