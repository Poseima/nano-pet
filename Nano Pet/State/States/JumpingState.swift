//
//  JumpingState.swift
//  Dream Pet
//
//  Jumping state - pet performs a smooth parabolic jump arc.
//  The pet jumps forward and high, then falls back down naturally.
//

import Foundation
import CoreGraphics

final class JumpingState: PetState {
    let name = "jumping"
    let priority = BehaviorPriority.ambient
    let isInterruptible = false

    // MARK: - Jump Configuration

    /// Initial upward velocity (determines jump height)
    private let jumpPower: CGFloat = 16.0

    /// Forward velocity (determines horizontal distance)
    private let forwardSpeed: CGFloat = 4.0

    /// Direction of the jump
    private let direction: Direction

    // MARK: - State Tracking

    private var ticksInState: UInt64 = 0
    private var phase: JumpPhase = .launch
    private var peakReached = false
    private var previousVelocityY: CGFloat = 0

    private enum JumpPhase {
        case launch     // Initial impulse frame
        case ascending  // Rising through the air
        case descending // Falling back down
    }

    // MARK: - Initialization

    init(direction: Direction = .randomHorizontal) {
        self.direction = direction
    }

    func enter(context: StateContext) {
        ticksInState = 0
        phase = .launch
        peakReached = false
        previousVelocityY = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1

        switch phase {
        case .launch:
            // First tick: apply the jump impulse with forward motion
            phase = .ascending
            previousVelocityY = jumpPower

            // Calculate horizontal velocity based on direction
            let dx: CGFloat
            switch direction {
            case .left:
                dx = -forwardSpeed
            case .right:
                dx = forwardSpeed
            case .up, .down:
                // For up/down, pick a random horizontal direction
                dx = Bool.random() ? forwardSpeed : -forwardSpeed
            }

            return StateDecision(
                motionIntent: .throwWithVelocity(CGVector(dx: dx, dy: jumpPower)),
                frameHint: .clip("jump", direction: direction.horizontalDirection),
                soundTrigger: "jump",
                spawnChild: false
            )

        case .ascending:
            // Check if we've reached the peak (velocity changes from positive to negative)
            let currentVelocityY = perception.velocity.dy
            if currentVelocityY <= 0 && previousVelocityY > 0 {
                phase = .descending
                peakReached = true
            }
            previousVelocityY = currentVelocityY

            // Continue with gravity, show jump frame during ascent
            return StateDecision(
                motionIntent: .fall,
                frameHint: .clip("jump", direction: direction.horizontalDirection),
                soundTrigger: nil,
                spawnChild: false
            )

        case .descending:
            // Falling back down - show fall frame
            return StateDecision(
                motionIntent: .fall,
                frameHint: .clip("fall", direction: direction.horizontalDirection),
                soundTrigger: nil,
                spawnChild: false
            )
        }
    }

    func nextState(perception: Perception) -> (any PetState)? {
        // Only transition to landing after we've started descending and hit ground
        if phase == .descending && (perception.isOnFloor || perception.isOnWindowTop) {
            return LandingState()
        }

        // Safety: if we've been in the air too long, force landing check
        if ticksInState > 120 && !perception.isInAir {
            return LandingState()
        }

        // While ascending or at peak, stay in jumping state
        return nil
    }
}

// MARK: - Direction Extension

private extension Direction {
    /// Get the horizontal equivalent direction
    var horizontalDirection: Direction {
        switch self {
        case .left, .right:
            return self
        case .up, .down:
            return .right // Default to right for vertical directions
        }
    }
}
