//
//  WalkingState.swift
//  Dream Pet
//
//  Walking state - pet walks in a direction until hitting a wall or time expires.
//

import Foundation

final class WalkingState: PetState {
    let name = "walking"
    let priority = BehaviorPriority.ambient
    let isInterruptible = true

    private var direction: Direction
    private var ticksInState: UInt64 = 0
    private let walkDuration: UInt64  // Random 3-7 seconds

    init(direction: Direction) {
        self.direction = direction
        self.walkDuration = UInt64.random(in: 360...840)
    }

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1
        return StateDecision(
            motionIntent: .walk(direction: direction, speed: .normal),
            frameHint: .clip("walk", direction: direction),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        // 专注模式下不跳跃
        if AppSettings.shared.behaviorMode != .focus {
            // Random chance to jump while walking
            if Double.random(in: 0...1) < 0.005 && !AppSettings.shared.disableJumping {  // 0.5% per tick
                return JumpingState(direction: direction)
            }
        }

        // Hit wall
        if perception.isOnWall == direction {
            // 专注模式下不爬墙，只转向
            if AppSettings.shared.behaviorMode != .focus && Double.random(in: 0...1) < 0.3 {
                return ClimbingState(wall: direction, direction: .up)
            }
            // Turn around
            direction = direction.opposite
            return nil
        }

        // Time to stop?
        if ticksInState >= walkDuration {
            return IdleState()
        }

        return nil
    }
}
