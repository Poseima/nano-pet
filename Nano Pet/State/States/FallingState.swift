//
//  FallingState.swift
//  Dream Pet
//
//  Falling state - pet falls due to gravity.
//

import Foundation

final class FallingState: PetState {
    let name = "falling"
    let priority = BehaviorPriority.physics
    let isInterruptible = false  // Can't interrupt physics

    func enter(context: StateContext) {}
    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        return StateDecision(motionIntent: .fall, frameHint: .frame(4), soundTrigger: nil, spawnChild: false)
    }

    func nextState(perception: Perception) -> (any PetState)? {
        if perception.isOnFloor || perception.isOnWindowTop {
            return LandingState()
        }
        // Grab wall while falling?
        if let wall = perception.isOnWall, Bool.random() && Double.random(in: 0...1) < 0.3 {
            return ClimbingState(wall: wall, direction: .up)
        }
        return nil
    }
}
