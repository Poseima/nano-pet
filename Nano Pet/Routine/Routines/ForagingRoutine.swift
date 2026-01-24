//
//  ForagingRoutine.swift
//  Nano Pet
//
//  Foraging routine - pet searches for something interesting.
//  Emotion: Curious → Satisfied discovery
//
//  Steps:
//  1. lookAround (6s) - Smell something?
//  2. walking (9s) - Walk a bit to find it
//  3. sitting (6s) - Stop and sniff
//  4. walking (12s) - Keep searching
//  5. sitting (4.5s) - Stop again
//  6. poseShowing (10.8s) - Found it! Happy!
//
//  Total: ~48 seconds
//

import Foundation

final class ForagingRoutine: LinearRoutine {

    init() {
        super.init(
            name: "foraging",
            priority: .normal,
            isInterruptible: true,
            emotion: "Curious → Satisfied, found something interesting!",
            steps: [
                RoutineStep(
                    state: LookAroundState(),
                    duration: 360,  // 6 seconds
                    description: "Smelled something?"
                ),
                RoutineStep(
                    state: WalkingState(direction: .randomHorizontal),
                    duration: 540,  // 9 seconds
                    description: "Walking to find it"
                ),
                RoutineStep(
                    state: SittingState(),
                    duration: 360,  // 6 seconds
                    description: "Stop and sniff"
                ),
                RoutineStep(
                    state: WalkingState(direction: .randomHorizontal),
                    duration: 720,  // 12 seconds
                    description: "Keep searching"
                ),
                RoutineStep(
                    state: SittingState(),
                    duration: 270,  // 4.5 seconds
                    description: "Stop again"
                ),
                RoutineStep(
                    state: PoseShowingState(),
                    duration: 648,  // 10.8 seconds
                    description: "Found it! Happy!"
                )
            ]
        )
    }
}
