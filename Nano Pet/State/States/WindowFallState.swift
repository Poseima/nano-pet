//
//  WindowFallState.swift
//  Dream Pet
//
//  Window fall state - pet falls off a window edge.
//

import Foundation

final class WindowFallState: PetState {
    let name = "windowFalling"
    let priority = BehaviorPriority.physics
    let isInterruptible = false

    private var ticksInState: UInt64 = 0
    private let fallTransitionDelay: UInt64 = 12  // Brief animation before full fall

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1
        return StateDecision(
            motionIntent: .fall,
            frameHint: .clip("window_fall"),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        // Transition to regular falling after brief window fall animation
        if ticksInState >= fallTransitionDelay {
            return FallingState()
        }

        // Landed on floor or another window
        if perception.isOnFloor || perception.isOnWindowTop {
            return LandingState()
        }

        return nil
    }
}
