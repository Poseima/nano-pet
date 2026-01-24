//
//  MorningStretchRoutine.swift
//  Nano Pet
//
//  Morning stretch routine - pet wakes up and stretches.
//  Emotion: Sleepy → Refreshed
//
//  Steps:
//  1. sitting (6s) - Just woke up
//  2. sitLookUp (9s) - Look up, yawn
//  3. sitStretch (12s) - Stretch
//  4. lookAround (9s) - Look around
//  5. walking (15s) - Start the new day
//
//  Total: 51 seconds
//

import Foundation

final class MorningStretchRoutine: LinearRoutine {

    init() {
        super.init(
            name: "morningStretch",
            priority: .normal,
            isInterruptible: true,
            emotion: "Sleepy → Refreshed, starting a new day",
            steps: [
                RoutineStep(
                    state: SittingState(),
                    duration: 360,  // 6 seconds
                    description: "Just woke up, sitting"
                ),
                RoutineStep(
                    state: SitLookUpState(),
                    duration: 540,  // 9 seconds
                    description: "Looking up, yawning"
                ),
                RoutineStep(
                    state: SitStretchState(),
                    duration: 720,  // 12 seconds
                    description: "Stretching"
                ),
                RoutineStep(
                    state: LookAroundState(),
                    duration: 540,  // 9 seconds
                    description: "Looking around"
                ),
                RoutineStep(
                    state: WalkingState(direction: .randomHorizontal),
                    duration: 900,  // 15 seconds
                    description: "Starting the new day"
                )
            ]
        )
    }
}
