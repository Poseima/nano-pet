//
//  TeleportOutState.swift
//  Dream Pet
//
//  Teleport out state - pet disappears with fade animation when app switches.
//

import Foundation

final class TeleportOutState: PetState {
    let name = "teleport_out"
    let priority = BehaviorPriority.reactive
    let isInterruptible = false

    private var ticksInState: UInt64 = 0
    private let disappearDuration: UInt64 = 60  // 1 second at 60fps
    private let targetWindow: WindowInfo

    init(targetWindow: WindowInfo) {
        self.targetWindow = targetWindow
    }

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1
        return StateDecision(
            motionIntent: .stay,
            frameHint: .clip("teleport_out"),
            soundTrigger: ticksInState == 1 ? "teleport" : nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        if ticksInState >= disappearDuration {
            // Teleport to target window and start appearing
            return TeleportInState(targetWindow: targetWindow)
        }
        return nil
    }

    /// Get the progress of the teleport animation (0.0 to 1.0)
    var progress: Double {
        min(1.0, Double(ticksInState) / Double(disappearDuration))
    }
}
