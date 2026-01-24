//
//  IdleState.swift
//  Dream Pet
//
//  Idle state - pet stands still and occasionally transitions to other behaviors.
//

import Foundation

final class IdleState: PetState {
    let name = "idle"
    let priority = BehaviorPriority.idle
    let isInterruptible = true

    private var ticksInState: UInt64 = 0
    private var idleDuration: UInt64

    init(duration: UInt64? = nil) {
        // 使用设置中的频率，或自定义值
        self.idleDuration = duration ?? AppSettings.shared.idleDurationTicks
    }

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1
        return StateDecision(motionIntent: .stay, frameHint: .frame(1), soundTrigger: nil, spawnChild: false)
    }

    func nextState(perception: Perception) -> (any PetState)? {
        guard ticksInState >= idleDuration else { return nil }

        // 专注模式：基础动作 + 坐姿变化 + 悬挂
        if AppSettings.shared.behaviorMode == .focus {
            let roll = Int.random(in: 0..<100)
            switch roll {
            case 0..<25: return WalkingState(direction: .randomHorizontal)
            case 25..<40: return SittingState()
            case 40..<50: return LookAroundState()
            case 50..<60: return LyingState()
            case 60..<70: return SitLookUpState()
            case 70..<80: return SitStretchState()
            case 80..<90: return DanglingState()
            default: return nil  // Stay idle
            }
        }

        // 随机模式：完整行为
        let roll = Int.random(in: 0..<100)
        switch roll {
        case 0..<25: return WalkingState(direction: .randomHorizontal)
        case 25..<40: return SittingState()
        case 40..<50: return AppSettings.shared.disableJumping ? nil : JumpingState()
        case 50..<60: return LookAroundState()
        case 60..<70: return LyingState()
        case 70..<80: return randomTeleportState()      // 10% teleport
        case 80..<90: return PoseShowingState()         // 10% pose showing
        default: return nil  // Stay idle longer
        }
    }

    // MARK: - Random Window Behaviors

    /// Get a random window and teleport to it
    private func randomTeleportState() -> (any PetState)? {
        let windows = WindowDetector.shared.windows
        guard let targetDetected = windows.randomElement() else { return nil }
        let targetWindow = WindowInfo(
            id: targetDetected.id,
            frame: targetDetected.frame,
            topY: targetDetected.topEdge,
            name: targetDetected.ownerName
        )
        return TeleportOutState(targetWindow: targetWindow)
    }
}
