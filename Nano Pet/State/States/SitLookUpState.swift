//
//  SitLookUpState.swift
//  Dream Pet
//
//  Sit look up state - pet looks up while sitting.
//

import Foundation

final class SitLookUpState: PetState {
    let name = "sitLookUp"
    let priority = BehaviorPriority.ambient
    let isInterruptible = true

    private var ticksInState: UInt64 = 0
    private let lookUpDuration: UInt64 = 1200  // 20 seconds

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1
        return StateDecision(
            motionIntent: .stay,
            frameHint: .clip("sit_lookup"),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        if ticksInState >= lookUpDuration {
            return SittingState()
        }
        return nil
    }
}
