//
//  WindowWalkState.swift
//  Dream Pet
//
//  Window walk state - pet walks on top of a detected window.
//

import Foundation

final class WindowWalkState: PetState {
    let name = "windowWalking"
    let priority = BehaviorPriority.ambient
    let isInterruptible = true

    private let window: WindowInfo
    private var direction: Direction
    private var ticksInState: UInt64 = 0

    init(window: WindowInfo, direction: Direction = .right) {
        self.window = window
        self.direction = direction
    }

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1

        // DEBUG: Log every 60 ticks (1 sec) - single line
        if ticksInState % 60 == 1 {
            let winName = perception.windowBelow?.name ?? "nil"
            print("[WindowWalk] t=\(ticksInState) pos=(\(Int(perception.petPosition.x)),\(Int(perception.petPosition.y))) dir=\(direction) win=\(winName) onTop=\(perception.isOnWindowTop)")
        }

        // Use stored window for edge detection, perception.windowBelow might fail
        // after teleport due to position/coordinate mismatches
        let currentWindow = perception.windowBelow ?? window

        let petWidth: CGFloat = 128
        let position = perception.petPosition

        // Turn around at window edges (with 5px margin)
        if direction == .right && position.x >= currentWindow.rightX - petWidth - 5 {
            direction = .left
        } else if direction == .left && position.x <= currentWindow.leftX + 5 {
            direction = .right
        }

        return StateDecision(
            motionIntent: .walk(direction: direction, speed: .slow),
            frameHint: .clip("window_walk", direction: direction),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        // Give time for position to stabilize after teleport
        // Only check isOnWindowTop after a few ticks
        if ticksInState > 5 && !perception.isOnWindowTop {
            // Double-check: if we're horizontally within our stored window bounds,
            // we might just have a detection glitch - stay walking
            let pos = perception.petPosition
            let petWidth: CGFloat = 128
            let inWindowX = pos.x >= window.leftX && pos.x <= window.rightX - petWidth

            if !inWindowX {
                // Actually walked off the window horizontally
                print("[WindowWalk] EXIT: walked off window horizontally pos=\(pos)")
                return WindowFallState()
            }
            // Stay in walk state if we're still horizontally on the window
            // (detection may have failed temporarily)
        }

        // Random chance to stop walking and sit/dangle
        if ticksInState > 180 && Double.random(in: 0...1) < 0.01 {
            return DanglingState()
        }

        // Random chance to turn around
        if ticksInState > 60 && ticksInState % 120 == 0 && Double.random(in: 0...1) < 0.2 {
            direction = direction.opposite
        }

        return nil
    }
}
