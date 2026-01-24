//
//  TeleportInState.swift
//  Dream Pet
//
//  Teleport in state - pet reappears with fade animation at new window.
//

import Foundation
import CoreGraphics

final class TeleportInState: PetState {
    let name = "teleport_in"
    let priority = BehaviorPriority.reactive
    let isInterruptible = false

    private var ticksInState: UInt64 = 0
    private let appearDuration: UInt64 = 60  // 1 second at 60fps
    private let targetWindow: WindowInfo
    private var hasTeleported = false

    init(targetWindow: WindowInfo) {
        self.targetWindow = targetWindow
    }

    func enter(context: StateContext) {
        ticksInState = 0
        hasTeleported = false
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1

        // On first tick, request position change to window edge
        if !hasTeleported {
            hasTeleported = true

            // Use latest active window data instead of stale targetWindow snapshot
            // This prevents teleporting to outdated coordinates when the window moved during animation
            let window = perception.activeWindow ?? targetWindow

            // Calculate spawn position on window's top edge
            let spawnX = window.leftX + (window.frame.width / 2) - 64
            let spawnY = window.topY

            print("[TeleportIn] Teleporting to window '\(window.name)' at (\(spawnX), \(spawnY))")
            print("[TeleportIn] Window frame: \(window.frame), topY: \(window.topY)")
            print("[TeleportIn] activeWindow: \(perception.activeWindow?.name ?? "nil"), targetWindow: \(targetWindow.name)")

            return StateDecision(
                motionIntent: .teleportTo(CGPoint(x: spawnX, y: spawnY)),
                frameHint: .clip("teleport_in"),
                soundTrigger: "teleport",
                spawnChild: false
            )
        }

        return StateDecision(
            motionIntent: .stay,
            frameHint: .clip("teleport_in"),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        if ticksInState >= appearDuration {
            let direction: Direction = Bool.random() ? .left : .right

            print("[TeleportIn] DONE: pos=(\(Int(perception.petPosition.x)),\(Int(perception.petPosition.y))) winBelow=\(perception.windowBelow?.name ?? "nil") onTop=\(perception.isOnWindowTop)")

            // Prefer detected window, fall back to target window
            if let detectedWindow = perception.windowBelow {
                print("[TeleportIn] → WindowWalk on '\(detectedWindow.name)'")
                return WindowWalkState(window: detectedWindow, direction: direction)
            }

            // Detection failed - use fallback
            let targetInfo = perception.activeWindow ?? targetWindow
            print("[TeleportIn] → WindowWalk FALLBACK on '\(targetInfo.name)'")
            return WindowWalkState(window: targetInfo, direction: direction)
        }
        return nil
    }

    /// Get the progress of the teleport animation (0.0 to 1.0)
    var progress: Double {
        min(1.0, Double(ticksInState) / Double(appearDuration))
    }
}
