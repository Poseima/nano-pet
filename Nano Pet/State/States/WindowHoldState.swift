//
//  WindowHoldState.swift
//  Nano Pet
//
//  Window hold state - pet hangs from the bottom edge of a window.
//  Uses frames 34-36 for the holding animation.
//

import Foundation
import CoreGraphics

final class WindowHoldState: PetState {
    let name = "windowHolding"
    let priority = BehaviorPriority.ambient
    let isInterruptible = true

    private let window: WindowInfo
    private let targetPosition: CGPoint  // Position to teleport to
    private var direction: Direction
    private var ticksInState: UInt64 = 0

    init(window: WindowInfo, direction: Direction? = nil) {
        self.window = window
        self.direction = direction ?? (Bool.random() ? .right : .left)

        // Empirically determined offsets from user testing
        let xOffset: CGFloat = 68
        let yOffset: CGFloat = 45

        let xPosition: CGFloat
        if self.direction == .right {
            // Facing right → hold bottom-LEFT corner
            xPosition = max(0, window.leftX - xOffset)
        } else {
            // Facing left → hold bottom-RIGHT corner
            xPosition = window.rightX - xOffset
        }

        let yPosition = max(0, window.bottomY - yOffset)

        self.targetPosition = CGPoint(x: xPosition, y: yPosition)
    }

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1

        return StateDecision(
            motionIntent: .teleportTo(targetPosition),
            frameHint: .clip("window_hold", direction: direction),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        // Random chance to let go and fall (2% per tick after 3 seconds)
        if ticksInState > 180 && Double.random(in: 0...1) < 0.02 {
            return FallingState()
        }

        // Skip boundary check for first few ticks to allow teleport to complete
        if ticksInState < 5 {
            return nil
        }

        // If we somehow lost the window (moved too far), fall
        let petCenterX = perception.petPosition.x + 64
        if petCenterX < window.leftX - 20 || petCenterX > window.rightX + 20 {
            return FallingState()
        }

        return nil
    }
}
