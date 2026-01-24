//
//  PullupState.swift
//  Dream Pet
//
//  Pullup state - pet reaches down while dangling to pull up another pet.
//

import Foundation

final class PullupState: PetState {
    let name = "pullup"
    let priority = BehaviorPriority.ambient
    let isInterruptible = false

    private var ticksInState: UInt64 = 0
    private let pullupDuration: UInt64 = 120  // Duration of pullup animation (4 frames * 30 ticks)
    private var hasSpawned = false

    func enter(context: StateContext) {
        ticksInState = 0
        hasSpawned = false
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1

        // Spawn child at the end of the animation (when "pulling up" is complete)
        let shouldSpawn = ticksInState == pullupDuration - 8 && !hasSpawned
        if shouldSpawn {
            hasSpawned = true
            print("[PullupState] tick=\(ticksInState) 触发拉起生成！spawnChild=true")
        }

        return StateDecision(
            motionIntent: .stay,
            frameHint: .clip("pullup"),
            soundTrigger: shouldSpawn ? "pullup" : nil,
            spawnChild: shouldSpawn
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        if ticksInState >= pullupDuration {
            // Return to dangling after pullup is complete
            return DanglingState()
        }
        return nil
    }
}
