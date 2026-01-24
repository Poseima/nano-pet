//
//  ExerciseRoutine.swift
//  Nano Pet
//
//  Exercise routine - pet does morning exercise.
//  Emotion: Energetic → Healthy and fit
//
//  Steps:
//  1. walking (9s) - Warm up walk
//  2. jumping (3s) - Jump
//  3. walking (9s) - Run in opposite direction
//  4. jumping (3s) - Jump again
//  5. sitting (6s) - Rest a moment
//  6. sitStretch (9s) - Stretch
//  7. walking (9s) - Cool down
//
//  Total: 48 seconds
//

import Foundation

final class ExerciseRoutine: LinearRoutine {

    init() {
        super.init(
            name: "exercise",
            priority: .normal,
            isInterruptible: true,
            emotion: "Energetic → Healthy and fit, staying active",
            steps: [
                RoutineStep(
                    state: WalkingState(direction: .left),
                    duration: 540,  // 9 seconds
                    description: "Warm up walk"
                ),
                RoutineStep(
                    state: JumpingState(direction: .left),
                    duration: 180,  // 3 seconds
                    description: "Jump"
                ),
                RoutineStep(
                    state: WalkingState(direction: .right),
                    duration: 540,  // 9 seconds
                    description: "Run in opposite direction"
                ),
                RoutineStep(
                    state: JumpingState(direction: .right),
                    duration: 180,  // 3 seconds
                    description: "Jump again"
                ),
                RoutineStep(
                    state: SittingState(),
                    duration: 360,  // 6 seconds
                    description: "Rest a moment"
                ),
                RoutineStep(
                    state: SitStretchState(),
                    duration: 540,  // 9 seconds
                    description: "Stretching"
                ),
                RoutineStep(
                    state: WalkingState(direction: .randomHorizontal),
                    duration: 540,  // 9 seconds
                    description: "Cool down"
                )
            ]
        )
    }
}
