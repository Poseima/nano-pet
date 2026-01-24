//
//  SunbathingRoutine.swift
//  Nano Pet
//
//  Sunbathing routine - pet finds a sunny spot and enjoys the warmth.
//  Emotion: Seeking warmth → Blissfully warm
//
//  Steps:
//  1. walking (12s) - Find a sunny spot
//  2. sitting (12s) - Sit in the sun
//  3. lying (24s) - Lie down comfortably
//  4. sitStretch (9s) - Stretch
//  5. lying (21s) - Continue enjoying
//
//  Total: 78 seconds
//

import Foundation

final class SunbathingRoutine: LinearRoutine {

    init() {
        super.init(
            name: "sunbathing",
            priority: .normal,
            isInterruptible: true,
            emotion: "Seeking warmth → Blissfully warm, enjoying the sun",
            steps: [
                RoutineStep(
                    state: WalkingState(direction: .randomHorizontal),
                    duration: 720,  // 12 seconds
                    description: "Finding a sunny spot"
                ),
                RoutineStep(
                    state: SittingState(),
                    duration: 720,  // 12 seconds
                    description: "Sitting in the sun"
                ),
                RoutineStep(
                    state: LyingState(),
                    duration: 1440,  // 24 seconds
                    description: "Lying down comfortably"
                ),
                RoutineStep(
                    state: SitStretchState(),
                    duration: 540,  // 9 seconds
                    description: "Stretching"
                ),
                RoutineStep(
                    state: LyingState(),
                    duration: 1260,  // 21 seconds
                    description: "Continue enjoying"
                )
            ]
        )
    }
}
