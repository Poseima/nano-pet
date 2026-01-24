//
//  DraggedState.swift
//  Dream Pet
//
//  Dragged state - pet is being held by the user.
//

import Foundation
import CoreGraphics

final class DraggedState: PetState {
    let name = "dragged"
    let priority = BehaviorPriority.forced
    let isInterruptible = false

    private var lastCursorPosition: CGPoint = .zero
    private var cursorVelocity: CGVector = .zero
    private var previousOffset: CGFloat = 0
    private var ticksInState: UInt64 = 0

    // Struggle animation frames (swaying left and right)
    private let struggleFrames = [5, 6, 7, 8, 9, 10, 9, 8, 7, 6]
    private let struggleFrameDuration = 18  // 18 ticks per frame (~0.3 sec)

    func enter(context: StateContext) {
        lastCursorPosition = .zero
        cursorVelocity = .zero
        previousOffset = 0
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1

        // Calculate cursor velocity for throw
        if lastCursorPosition != .zero {
            let newVelocity = CGVector(
                dx: perception.cursorPosition.x - lastCursorPosition.x,
                dy: perception.cursorPosition.y - lastCursorPosition.y
            )
            // Smooth the velocity
            cursorVelocity = CGVector(
                dx: cursorVelocity.dx * 0.5 + newVelocity.dx * 0.5,
                dy: cursorVelocity.dy * 0.5 + newVelocity.dy * 0.5
            )
        }
        lastCursorPosition = perception.cursorPosition

        // Calculate current struggle frame (cycles through frames continuously)
        let frameIndex = Int((ticksInState / UInt64(struggleFrameDuration)) % UInt64(struggleFrames.count))
        let currentFrame = struggleFrames[frameIndex]

        return StateDecision(
            motionIntent: .followCursor,
            frameHint: .frame(currentFrame),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        if !perception.isDragged {
            // Check if dropped on a window top
            if perception.isOnWindowTop, let window = perception.windowBelow {
                return WindowWalkState(window: window, direction: .randomHorizontal)
            }

            // Thrown!
            let throwPower = hypot(cursorVelocity.dx, cursorVelocity.dy)
            if throwPower > 5 {
                return ThrownState(velocity: cursorVelocity)
            }
            return FallingState()
        }
        return nil
    }
}
