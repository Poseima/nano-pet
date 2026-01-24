//
//  StateEngine.swift
//  Dream Pet
//
//  A hierarchical state machine with priority interrupts.
//

import Foundation
import CoreGraphics

// MARK: - State Engine

/// Engine for managing pet behavior states
final class StateEngine {

    // MARK: - State Stack

    private var stateStack: [any PetState] = []

    // Track the last processed active app name to prevent duplicate triggers
    // when multiple pets process the same app change event
    private var lastProcessedActiveApp: String = ""

    // Bug #6 fix: Track whether we've already tried to trigger a routine this idle period
    // This prevents the 50% check from happening every tick while idle
    private var hasTriedRoutineThisIdlePeriod: Bool = false

    // MARK: - Routine Engine Reference

    /// Reference to routine engine for coordination
    weak var routineEngine: RoutineEngine?

    // MARK: - Pet Identity (for logging)

    /// 宠物身份标识，用于日志记录
    var petIdentifier: String = "Unknown"

    /// Current active state
    var currentState: any PetState {
        stateStack.last ?? IdleState()
    }

    // MARK: - Behavior Probability Table (data-driven)

    var behaviorWeights: [String: Int] = [
        "walk": 30,
        "sit": 20,
        "jump": 5,
        "lookAround": 15,
        "lie": 10,
        "climb": 10,
        "curious": 10,
    ]

    // MARK: - Initialization

    init() {
        stateStack = [IdleState()]
    }

    // MARK: - State Management

    /// Push a new state onto the stack
    /// - Parameter state: State to push
    func pushState(_ state: any PetState) {
        if state.priority >= currentState.priority || currentState.isInterruptible {
            let previousState = currentState.name
            print("[StateEngine] [\(petIdentifier)] 推入状态: \(previousState) → \(state.name)")
            currentState.exit(context: makeContext())
            stateStack.append(state)
            state.enter(context: makeContext())
        }
    }

    /// Pop the current state from the stack
    func popState() {
        guard stateStack.count > 1 else { return }
        currentState.exit(context: makeContext())
        stateStack.removeLast()
        currentState.enter(context: makeContext())
    }

    /// Clear all states and reset to idle
    func reset() {
        stateStack.forEach { $0.exit(context: makeContext()) }
        stateStack = [IdleState()]
        stateStack[0].enter(context: makeContext())
    }

    /// Force a state change, clearing the stack
    /// - Parameter state: State to transition to
    func forceState(_ state: any PetState) {
        let previousState = currentState.name
        print("[StateEngine] [\(petIdentifier)] 强制状态切换: \(previousState) → \(state.name)")
        stateStack.forEach { $0.exit(context: makeContext()) }
        stateStack = [state]
        state.enter(context: makeContext())
    }

    // MARK: - Think

    /// Process one tick of thinking
    /// - Parameters:
    ///   - perception: Current environment perception
    ///   - currentTick: Current tick count
    /// - Returns: Decision for this tick
    func think(perception: Perception, currentTick: UInt64) -> StateDecision {
        // Check for forced state changes based on perception (Bug #5 fix: pass currentTick)
        handleForcedStateChanges(perception: perception, currentTick: currentTick)

        // Let current state decide
        var decision = currentState.think(perception: perception, tick: currentTick)

        // Check if routine engine wants to advance to next step
        if let routineEngine = routineEngine, routineEngine.hasActiveRoutine {
            let context = RoutineContext.current(
                tick: currentTick,
                position: position,
                perception: perception
            )
            if let routineNext = routineEngine.tick(stateName: currentState.name, context: context) {
                // Routine wants to advance
                let previousState = currentState.name
                print("[StateEngine] [\(petIdentifier)] Routine 状态切换: \(previousState) → \(routineNext.name)")
                currentState.exit(context: makeContext())
                stateStack[stateStack.count - 1] = routineNext
                routineNext.enter(context: makeContext())
                decision = currentState.think(perception: perception, tick: currentTick)
                return decision
            }
        }

        // Check for natural transition
        if let next = currentState.nextState(perception: perception) {
            var finalNext = next

            // Bug #6 fix: Only check routine trigger ONCE per idle period
            // If coming from idle and haven't tried yet, 50% chance to start a routine instead
            if currentState.name == "idle" && !hasTriedRoutineThisIdlePeriod {
                hasTriedRoutineThisIdlePeriod = true  // Mark that we've tried, regardless of outcome

                if shouldTriggerRoutine() {
                    if let routineEngine = routineEngine {
                        let context = RoutineContext.current(
                            tick: currentTick,
                            position: position,
                            perception: perception
                        )
                        if let routineFirst = routineEngine.startRandomRoutine(context: context) {
                            finalNext = routineFirst
                        }
                    }
                }
            }

            // Direct replacement - bypasses priority checks since state requested this
            let previousState = currentState.name

            // Reset the routine trigger flag when leaving idle
            if previousState == "idle" {
                hasTriedRoutineThisIdlePeriod = false
            }

            print("[StateEngine] [\(petIdentifier)] 自然状态切换: \(previousState) → \(finalNext.name)")
            currentState.exit(context: makeContext())
            stateStack[stateStack.count - 1] = finalNext
            finalNext.enter(context: makeContext())
            decision = currentState.think(perception: perception, tick: currentTick)
        }

        return decision
    }

    /// Determine if a routine should be triggered (50% chance)
    private func shouldTriggerRoutine() -> Bool {
        // Only in random mode, not focus mode
        guard AppSettings.shared.behaviorMode != .focus else { return false }

        // 50% chance
        return Int.random(in: 0..<100) < 50
    }

    // MARK: - Forced State Handling

    private func handleForcedStateChanges(perception: Perception, currentTick: UInt64) {
        // Dragging takes priority
        if perception.isDragged && !(currentState is DraggedState) {
            // Cancel active routine when dragged
            // Bug #5 fix: Use currentTick instead of 0
            if let routineEngine = routineEngine, routineEngine.hasActiveRoutine {
                let context = RoutineContext.current(
                    tick: currentTick,
                    position: position,
                    perception: perception
                )
                routineEngine.cancelRoutine(context: context)
            }
            pushState(DraggedState())
            return
        }

        // Teleport to active window when app changes (only in random mode)
        // In focus mode, pets should stay on their assigned screen
        // Per-pet tracking: only trigger if this pet hasn't processed this app change yet
        if AppSettings.shared.behaviorMode != .focus,
           perception.activeAppDidChange,
           perception.activeAppName != lastProcessedActiveApp,
           let targetWindow = perception.activeWindow,
           !(currentState is TeleportOutState),
           !(currentState is TeleportInState) {
            lastProcessedActiveApp = perception.activeAppName
            pushState(TeleportOutState(targetWindow: targetWindow))
            return
        }

        // Always update the last processed app name when app changes
        // This ensures we don't re-trigger teleport for the same app switch
        if perception.activeAppDidChange {
            lastProcessedActiveApp = perception.activeAppName
        }

        // Falling in air (but not if already handling physics or landing)
        if perception.isInAir &&
           !(currentState is FallingState) &&
           !(currentState is JumpingState) &&
           !(currentState is ThrownState) &&
           !(currentState is DraggedState) &&
           !(currentState is ClimbingState) &&
           !(currentState is CeilingState) &&
           !(currentState is LandingState) &&
           !(currentState is WindowWalkState) &&
           !(currentState is WindowFallState) &&
           !(currentState is WindowHoldState) &&
           !(currentState is PullupState) &&
           !(currentState is TeleportOutState) &&
           !(currentState is TeleportInState) {
            pushState(FallingState())
        }
    }

    // MARK: - Context

    private var position: CGPoint = .zero

    func setPosition(_ pos: CGPoint) {
        position = pos
    }

    private func makeContext() -> StateContext {
        StateContext(tick: 0, position: position, perception: nil)
    }

    // MARK: - State Query

    /// Get all states in the stack
    var stateStackNames: [String] {
        stateStack.map { $0.name }
    }

    /// Check if currently in a specific state
    func isInState(_ name: String) -> Bool {
        stateStack.contains { $0.name == name }
    }

    /// Get the depth of the state stack
    var stateDepth: Int {
        stateStack.count
    }
}
