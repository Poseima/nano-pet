//
//  DanglingState.swift
//  Dream Pet
//
//  Dangling state - pet dangles its legs while sitting on an edge.
//

import Foundation

final class DanglingState: PetState {
    let name = "dangling"
    let priority = BehaviorPriority.ambient
    let isInterruptible = true

    private var ticksInState: UInt64 = 0
    private let dangleDuration: UInt64  // Random 5-12 seconds

    init() {
        self.dangleDuration = UInt64.random(in: 600...1440)
    }

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1
        return StateDecision(
            motionIntent: .stay,
            frameHint: .clip("dangle"),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        // Allow minimum time for animation to play before checking exit conditions
        guard ticksInState > 60 else {
            return nil
        }

        // Check if we're no longer on an edge (window disappeared or fell off)
        if !perception.isOnWindowTop {
            if perception.isOnFloor {
                return IdleState()
            }
            // Window disappeared while dangling - fall!
            return FallingState()
        }

        // Note: PullupState is only triggered via right-click menu, not automatically

        if ticksInState >= dangleDuration {
            return SittingState()
        }
        return nil
    }
}
