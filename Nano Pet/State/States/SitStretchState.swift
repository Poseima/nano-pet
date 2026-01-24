//
//  SitStretchState.swift
//  Dream Pet
//
//  Sit stretch state - pet stretches legs while sitting.
//

import Foundation

final class SitStretchState: PetState {
    let name = "sitStretch"
    let priority = BehaviorPriority.ambient
    let isInterruptible = true

    private var ticksInState: UInt64 = 0
    private let stretchDuration: UInt64 = 1200  // 20 seconds

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1
        return StateDecision(
            motionIntent: .stay,
            frameHint: .clip("sit_stretch"),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        if ticksInState >= stretchDuration {
            return SittingState()
        }
        return nil
    }
}
