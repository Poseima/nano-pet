//
//  DividingState.swift
//  Dream Pet
//
//  Dividing state - pet divides to spawn a new pet with dramatic animation.
//  Animation sequence: buildup pulse → stretch → split (spawn) → settle back
//

import Foundation

final class DividingState: PetState {
    let name = "dividing"
    let priority = BehaviorPriority.forced
    let isInterruptible = false

    private var ticksInState: UInt64 = 0
    // Animation: 15 frames × 12 ticks = 180 ticks total
    // Frames: [42, 43, 42, 43, 44, 45, 44, 45, 46, 46, 46, 45, 44, 43, 42]
    //          buildup pulse    |   stretch   |  split  | settle back
    private let divideDuration: UInt64 = 180
    private let spawnTick: UInt64 = 108  // Middle of the three frame-46s (tick 96 + 12)
    private var hasSpawned = false

    func enter(context: StateContext) {
        ticksInState = 0
        hasSpawned = false
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1

        // Spawn child at the climactic "split" moment (middle of frame 46 sequence)
        let shouldSpawn = ticksInState == spawnTick && !hasSpawned
        if shouldSpawn {
            hasSpawned = true
            print("[DividingState] tick=\(ticksInState) 触发分裂！spawnChild=true")
        }

        // Add a subtle bounce effect during the split
        let motionIntent: MotionIntent
        if ticksInState >= 48 && ticksInState <= 66 {
            // During split frames, slight upward motion
            motionIntent = .stay
        } else {
            motionIntent = .stay
        }

        return StateDecision(
            motionIntent: motionIntent,
            frameHint: .clip("divide"),
            soundTrigger: shouldSpawn ? "divide" : nil,
            spawnChild: shouldSpawn
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        if ticksInState >= divideDuration {
            // Return to idle with a happy state
            return IdleState()
        }
        return nil
    }
}
