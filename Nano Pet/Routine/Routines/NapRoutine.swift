//
//  NapRoutine.swift
//  Nano Pet
//
//  Nap routine - pet finds a comfortable spot and takes a nap.
//  Emotion: Tired → Relaxed
//
//  Steps:
//  1. walking (12s) - Find a comfortable spot
//  2. sitting (9s) - Sit down
//  3. sitStretch (9s) - Stretch before lying down
//  4. lying (30s) - Lying down resting
//  5. lying (30s) - Continue sleeping
//
//  Total: 90 seconds
//

import Foundation

final class NapRoutine: LinearRoutine {

    init() {
        super.init(
            name: "nap",
            priority: .normal,
            isInterruptible: true,
            emotion: "Tired → Relaxed, taking a comfortable nap",
            steps: [
                RoutineStep(
                    state: WalkingState(direction: .randomHorizontal),
                    duration: 720,  // 12 seconds
                    description: "Finding a comfortable spot"
                ),
                RoutineStep(
                    state: SittingState(),
                    duration: 540,  // 9 seconds
                    description: "Sitting down"
                ),
                RoutineStep(
                    state: SitStretchState(),
                    duration: 540,  // 9 seconds
                    description: "Stretching before lying down"
                ),
                RoutineStep(
                    state: LyingState(),
                    duration: 1800,  // 30 seconds
                    description: "Lying down, resting"
                ),
                RoutineStep(
                    state: LyingState(),
                    duration: 1800,  // 30 seconds
                    description: "Continue sleeping"
                )
            ]
        )
    }
}
