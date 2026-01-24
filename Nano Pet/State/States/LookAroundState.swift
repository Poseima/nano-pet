//
//  LookAroundState.swift
//  Dream Pet
//
//  Look around state - pet looks around curiously.
//

import Foundation

final class LookAroundState: PetState {
    let name = "lookAround"
    let priority = BehaviorPriority.ambient
    let isInterruptible = true

    private var ticksInState: UInt64 = 0
    private let lookDuration: UInt64 = 1200  // 20 seconds

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1
        return StateDecision(
            motionIntent: .stay,
            frameHint: .clip("sit_look"),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        if ticksInState >= lookDuration {
            // Random next behavior
            let roll = Int.random(in: 0..<100)
            switch roll {
            case 0..<40: return IdleState()
            case 40..<70: return SittingState()
            case 70..<90: return WalkingState(direction: .randomHorizontal)
            default: return LyingState()
            }
        }
        return nil
    }
}
