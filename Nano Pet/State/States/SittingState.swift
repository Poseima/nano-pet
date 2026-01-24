//
//  SittingState.swift
//  Dream Pet
//
//  Sitting state - pet sits in place.
//

import Foundation

final class SittingState: PetState {
    let name = "sitting"
    let priority = BehaviorPriority.ambient
    let isInterruptible = true

    private var ticksInState: UInt64 = 0
    private let sitDuration: UInt64  // Random 5-10 seconds

    init() {
        self.sitDuration = UInt64.random(in: 600...1200)
    }

    func enter(context: StateContext) {
        ticksInState = 0
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1
        return StateDecision(
            motionIntent: .stay,
            frameHint: .frame(11),
            soundTrigger: nil,
            spawnChild: false
        )
    }

    func nextState(perception: Perception) -> (any PetState)? {
        // Random sitting variations
        if ticksInState > 60 && ticksInState % 120 == 0 && Double.random(in: 0...1) < 0.3 {
            let variant = Int.random(in: 0..<3)
            switch variant {
            case 0: return LookAroundState()   // existing look around
            case 1: return SitLookUpState()    // frame 26 - look up
            default: return SitStretchState()  // frame 29 - stretch legs
            }
        }

        if ticksInState >= sitDuration {
            // Random next behavior
            let roll = Int.random(in: 0..<100)
            switch roll {
            case 0..<40: return IdleState()
            case 40..<70: return WalkingState(direction: .randomHorizontal)
            case 70..<90: return LyingState()
            default: return nil
            }
        }
        return nil
    }
}
