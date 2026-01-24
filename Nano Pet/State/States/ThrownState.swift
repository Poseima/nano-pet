//
//  ThrownState.swift
//  Dream Pet
//
//  Thrown state - pet was thrown by the user and is flying through the air.
//

import Foundation
import CoreGraphics

final class ThrownState: PetState {
    let name = "thrown"
    let priority = BehaviorPriority.physics
    let isInterruptible = false

    private let velocity: CGVector
    private var hasAppliedVelocity = false

    init(velocity: CGVector) {
        self.velocity = velocity
    }

    func enter(context: StateContext) {
        hasAppliedVelocity = false
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        if !hasAppliedVelocity {
            hasAppliedVelocity = true
            return StateDecision(
                motionIntent: .throwWithVelocity(velocity),
                frameHint: .frame(37),
                soundTrigger: "throw",
                spawnChild: false
            )
        }
        // Continue falling
        return StateDecision(motionIntent: .fall, frameHint: .frame(37), soundTrigger: nil, spawnChild: false)
    }

    func nextState(perception: Perception) -> (any PetState)? {
        if perception.isOnFloor || perception.isOnWindowTop {
            return LandingState()
        }
        // After initial throw, transition to falling
        if hasAppliedVelocity && perception.isInAir {
            return FallingState()
        }
        return nil
    }
}
