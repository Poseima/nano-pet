//
//  ClimbingState.swift
//  Dream Pet
//
//  Climbing state - pet climbs up or down a wall.
//

import Foundation

final class ClimbingState: PetState {
    let name = "climbing"
    let priority = BehaviorPriority.reactive
    let isInterruptible = true

    private let wall: Direction
    private var direction: Direction
    private var ticksInState: UInt64 = 0

    init(wall: Direction, direction: Direction) {
        self.wall = wall
        self.direction = direction
    }

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1
        return StateDecision(
            motionIntent: .climb(direction: direction),
            frameHint: .clip("climb", direction: wall),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        // Reached ceiling?
        if perception.isOnCeiling {
            // Corner escape: higher chance to fall instead of ceiling walk
            if perception.isOnWall != nil && Double.random(in: 0...1) < 0.3 {
                return FallingState()
            }
            return CeilingState(entryWall: wall)
        }

        // Reached floor?
        if perception.isOnFloor && direction == .down {
            return IdleState()
        }

        // Random dismount? (very low chance, only after extended climbing)
        if ticksInState > 300 && Double.random(in: 0...1) < 0.005 {
            return FallingState()
        }

        // Change direction? (very rare, creates interesting behavior)
        if ticksInState > 180 && Double.random(in: 0...1) < 0.002 {
            direction = direction == .up ? .down : .up
        }

        return nil
    }
}
