//
//  LandingState.swift
//  Dream Pet
//
//  Landing state - brief animation when landing from a fall.
//

import Foundation

final class LandingState: PetState {
    let name = "landing"
    let priority = BehaviorPriority.physics
    let isInterruptible = false

    private var ticksInState: UInt64 = 0
    private let landingDuration: UInt64 = 48  // Animation duration

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1
        return StateDecision(
            motionIntent: .stay,
            frameHint: .clip("land"),
            soundTrigger: ticksInState == 1 ? "land" : nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        if ticksInState >= landingDuration {
            return IdleState()
        }
        return nil
    }
}
