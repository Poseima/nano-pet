//
//  PoseShowingState.swift
//  Nano Pet
//
//  Pose showing state - pet does a cute pose sequence.
//  Animation: sit → look up → turn → arms up → cheer → return
//

import Foundation

final class PoseShowingState: PetState {
    let name = "poseShowing"
    let priority = BehaviorPriority.ambient
    let isInterruptible = true

    private var ticksInState: UInt64 = 0
    private let poseDuration: UInt64 = 1200  // 20 seconds

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1
        return StateDecision(
            motionIntent: .stay,
            frameHint: .clip("pose_show"),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        if ticksInState >= poseDuration {
            return IdleState()
        }
        return nil
    }
}
