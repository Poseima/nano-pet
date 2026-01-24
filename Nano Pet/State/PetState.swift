//
//  PetState.swift
//  Dream Pet
//
//  Protocol and types for pet behavior states.
//

import Foundation
import CoreGraphics

// MARK: - Behavior Priority

/// Priority levels for behavior states
enum BehaviorPriority: Int, Comparable {
    case idle = 0
    case ambient = 1      // Random behaviors
    case reactive = 2     // Environment reactions
    case physics = 3      // Falling, landing
    case forced = 4       // Dragged by user

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - State Decision

/// Decision made by a state each tick
struct StateDecision {
    let motionIntent: MotionIntent
    let frameHint: FrameHint?
    let soundTrigger: String?
    let spawnChild: Bool

    /// Default idle decision
    static let idle = StateDecision(
        motionIntent: .stay,
        frameHint: nil,
        soundTrigger: nil,
        spawnChild: false
    )

    /// Create a simple movement decision
    static func move(_ intent: MotionIntent, frame: FrameHint? = nil) -> StateDecision {
        StateDecision(motionIntent: intent, frameHint: frame, soundTrigger: nil, spawnChild: false)
    }
}

// MARK: - Pet State Protocol

/// Protocol for all pet behavior states
protocol PetState: AnyObject {
    /// Name of the state
    var name: String { get }

    /// Priority of this state
    var priority: BehaviorPriority { get }

    /// Whether this state can be interrupted
    var isInterruptible: Bool { get }

    /// Called when entering this state
    func enter(context: StateContext)

    /// Called when exiting this state
    func exit(context: StateContext)

    /// Called each tick to decide what to do
    func think(perception: Perception, tick: UInt64) -> StateDecision

    /// Determine if we should transition to another state
    func nextState(perception: Perception) -> (any PetState)?
}

// MARK: - Default Implementations

extension PetState {
    var isInterruptible: Bool { true }

    func enter(context: StateContext) {}
    func exit(context: StateContext) {}
}
