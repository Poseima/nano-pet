//
//  LyingState.swift
//  Dream Pet
//
//  Lying state - pet lies down to rest.
//

import Foundation

final class LyingState: PetState {
    let name = "lying"
    let priority = BehaviorPriority.ambient
    let isInterruptible = true

    private var ticksInState: UInt64 = 0
    private let lieDuration: UInt64  // Random 7-20 seconds

    init() {
        self.lieDuration = UInt64.random(in: 840...2400)
    }

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1
        return StateDecision(
            motionIntent: .stay,
            frameHint: .clip("lie"),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        if ticksInState >= lieDuration {
            return SittingState()
        }
        return nil
    }
}
