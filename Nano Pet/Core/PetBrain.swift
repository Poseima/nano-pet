//
//  PetBrain.swift
//  Dream Pet
//
//  Central orchestrator that coordinates all subsystems, runs the main loop,
//  and emits observable state for view binding.
//

import Foundation
import CoreGraphics
#if os(macOS)
import AppKit
#endif

// MARK: - Pet Brain

/// Central coordinator for pet behavior, physics, and animation
@Observable
final class PetBrain {

    // MARK: - Subsystems

    let stateEngine: StateEngine
    let physicsEngine: PhysicsEngine
    let frameEngine: FrameEngine
    let senseEngine: SenseEngine
    let routineEngine: RoutineEngine

    // MARK: - Observable Output (for view binding)

    /// Current frame number (1-46)
    private(set) var currentFrame: Int = 1

    /// Current position (bottom-left corner of pet)
    private(set) var position: CGPoint = .zero

    /// Whether sprite should be flipped horizontally
    private(set) var flipHorizontal: Bool = false

    /// Current state name for debugging
    private(set) var stateName: String = "idle"

    // MARK: - Pet Identity (for logging)

    /// 宠物身份标识，用于日志记录
    var petIdentifier: String = "Unknown" {
        didSet {
            stateEngine.petIdentifier = petIdentifier
            routineEngine.petIdentifier = petIdentifier
        }
    }

    // MARK: - Debug/Test Output

    /// Log of all ticks (when enabled)
    private(set) var tickLog: [TickLogEntry] = []

    /// Enable tick logging for testing
    var enableLogging: Bool = false

    /// Maximum log size (to prevent memory issues)
    var maxLogSize: Int = 10000

    // MARK: - Timing

    /// Current tick count
    private(set) var tickCount: UInt64 = 0

    /// Tick rate (60fps)
    let tickRate: TimeInterval = 1.0 / 60.0

    // MARK: - Callbacks

    /// Called when a child pet should be spawned
    var onSpawnChild: (() -> Void)?

    /// Called when a sound should be played
    var onPlaySound: ((String) -> Void)?

    /// Called when window position should update
    var onPositionChanged: ((CGPoint) -> Void)?

    // MARK: - Initialization

    init() {
        stateEngine = StateEngine()
        physicsEngine = PhysicsEngine()
        frameEngine = FrameEngine()
        senseEngine = SenseEngine()
        routineEngine = RoutineEngine()

        // Connect routine engine to registry and state engine
        routineEngine.registry = RoutineRegistry.shared
        stateEngine.routineEngine = routineEngine
    }

    // MARK: - Main Loop

    /// Process one tick of the simulation
    func tick() {
        tickCount += 1

        // 1. Sense: Gather environmental perception
        let perception = senseEngine.perceive(position: position)

        // 2. Think: State engine decides behavior
        stateEngine.setPosition(position)
        let decision = stateEngine.think(perception: perception, currentTick: tickCount)

        // 3. Act: Physics engine applies motion
        let motion = physicsEngine.apply(
            decision: decision,
            currentPosition: position,
            perception: perception
        )
        position = motion.newPosition

        // Safety: ensure position is never negative
        if position.x < 0 || position.y < 0 {
            position.x = max(0, position.x)
            position.y = max(0, position.y)
        }

        onPositionChanged?(position)

        // 4. Animate: Frame engine selects sprite
        let frameSelection: FrameSelection
        if let hint = decision.frameHint {
            frameSelection = frameEngine.selectFrame(hint: hint, tick: tickCount)
        } else {
            frameSelection = frameEngine.selectFrame(state: stateEngine.currentState, motion: motion, tick: tickCount)
        }
        currentFrame = frameSelection.number
        flipHorizontal = frameSelection.flipped

        // Update state name for UI
        stateName = stateEngine.currentState.name

        // 5. Handle callbacks
        if let sound = decision.soundTrigger {
            onPlaySound?(sound)
        }
        if decision.spawnChild {
            onSpawnChild?()
        }

        // 6. Log for testing
        if enableLogging {
            let entry = TickLogEntry(
                tick: tickCount,
                state: stateEngine.currentState.name,
                frame: currentFrame,
                position: position,
                perception: perception.summary
            )
            tickLog.append(entry)

            // Trim log if too large
            if tickLog.count > maxLogSize {
                tickLog.removeFirst(tickLog.count - maxLogSize)
            }
        }
    }

    // MARK: - Position Management

    /// Set the pet's position directly
    func setPosition(_ pos: CGPoint) {
        position = pos
        stateEngine.setPosition(pos)
    }

    /// Move the pet by a delta
    func moveBy(dx: CGFloat, dy: CGFloat) {
        position.x += dx
        position.y += dy
        stateEngine.setPosition(position)
    }

    // MARK: - State Control

    /// Force transition to a specific state
    func forceState(_ state: any PetState) {
        frameEngine.resetClipTracking()
        stateEngine.forceState(state)
    }

    /// Trigger divide behavior
    func triggerDivide() {
        forceState(DividingState())
    }

    /// Trigger jump
    func triggerJump() {
        stateEngine.pushState(JumpingState())
    }

    /// Start a specific routine, interrupting any current state
    func startRoutine(_ routine: any Routine) {
        // Cancel any existing routine
        routineEngine.cancelRoutine()

        // Create context for routine
        let context = RoutineContext(
            currentTick: tickCount,
            position: position,
            perception: senseEngine.perceive(position: position),
            timeOfDay: TimeAwareness.current
        )

        // Start the routine and get first state
        let firstState = routineEngine.startRoutine(routine, context: context)

        // Force transition to the first state
        frameEngine.resetClipTracking()
        stateEngine.forceState(firstState)
    }

    // MARK: - Input Handling

    /// Start dragging
    func startDrag() {
        senseEngine.isDragged = true
    }

    /// End dragging
    func endDrag() {
        senseEngine.isDragged = false
    }

    /// Register a tap
    func registerTap() {
        senseEngine.wasTapped = true
    }

    // MARK: - Testing Support

    /// Reset the brain to initial state
    func reset() {
        tickCount = 0
        position = .zero
        currentFrame = 1
        flipHorizontal = false
        stateName = "idle"
        tickLog.removeAll()
        stateEngine.reset()
        physicsEngine.reset()
    }

    /// Clear the tick log
    func clearLog() {
        tickLog.removeAll()
    }

    /// Get a summary of states visited
    var statesVisited: Set<String> {
        Set(tickLog.map { $0.state })
    }

    /// Get a summary of frames used
    var framesUsed: Set<Int> {
        Set(tickLog.map { $0.frame })
    }
}
