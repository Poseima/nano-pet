//
//  DeepSleepRoutine.swift
//  Nano Pet
//
//  Deep sleep routine - pet goes to sleep for the night.
//  Emotion: Drowsy → Sleeping soundly
//
//  Steps:
//  1. walking (9s) - Find a sleeping spot
//  2. sitting (6s) - Sit down
//  3. sitStretch (9s) - Yawn
//  4. lying (45s) - Fall asleep
//  5. lying (45s) - Continue deep sleep
//
//  Total: 114 seconds
//

import Foundation

final class DeepSleepRoutine: LinearRoutine {

    init() {
        super.init(
            name: "deepSleep",
            priority: .normal,
            isInterruptible: true,
            emotion: "Drowsy → Sleeping soundly, good night",
            steps: [
                RoutineStep(
                    state: WalkingState(direction: .randomHorizontal),
                    duration: 540,  // 9 seconds
                    description: "Finding a sleeping spot"
                ),
                RoutineStep(
                    state: SittingState(),
                    duration: 360,  // 6 seconds
                    description: "Sitting down"
                ),
                RoutineStep(
                    state: SitStretchState(),
                    duration: 540,  // 9 seconds
                    description: "Yawning"
                ),
                RoutineStep(
                    state: LyingState(),
                    duration: 2700,  // 45 seconds
                    description: "Falling asleep"
                ),
                RoutineStep(
                    state: LyingState(),
                    duration: 2700,  // 45 seconds
                    description: "Continue deep sleep"
                )
            ]
        )
    }
}
