//
//  CeilingState.swift
//  Dream Pet
//
//  Ceiling state - pet hangs from the ceiling and can walk across it.
//

import Foundation

final class CeilingState: PetState {
    let name = "ceiling"
    let priority = BehaviorPriority.reactive
    let isInterruptible = true

    private let entryWall: Direction
    private var walkDirection: Direction
    private var ticksInState: UInt64 = 0
    private var isWalking: Bool = false

    init(entryWall: Direction) {
        self.entryWall = entryWall
        // Start walking in opposite direction of entry
        self.walkDirection = entryWall.opposite
    }

    func enter(context: StateContext) {
        ticksInState = 0
        isWalking = false
    }

    func exit(context: StateContext) {}

    func think(perception: Perception, tick: UInt64) -> StateDecision {
        ticksInState += 1

        // Start walking after a pause
        if !isWalking && ticksInState > 60 {
            isWalking = Double.random(in: 0...1) < 0.02
        }

        if isWalking {
            return StateDecision(
                motionIntent: .ceilingWalk(direction: walkDirection),
                frameHint: .clip("ceiling", direction: walkDirection),
                soundTrigger: nil,
                spawnChild: false
            )
        } else {
            return StateDecision(
                motionIntent: .stay,
                frameHint: .clip("ceiling_hang"),
                soundTrigger: nil,
                spawnChild: false
            )
        }
    }

    func nextState(perception: Perception) -> (any PetState)? {
        // Corner escape: if at ceiling AND wall, chance to drop
        if perception.isOnWall != nil && Double.random(in: 0...1) < 0.05 {
            return FallingState()
        }

        // Hit wall while walking on ceiling
        if isWalking && perception.isOnWall == walkDirection {
            return ClimbingState(wall: walkDirection, direction: .down)
        }

        // Random drop
        if ticksInState > 180 && Double.random(in: 0...1) < 0.01 {
            return FallingState()
        }

        // Change direction
        if isWalking && ticksInState > 120 && Double.random(in: 0...1) < 0.02 {
            walkDirection = walkDirection.opposite
            isWalking = false
        }

        return nil
    }
}
