//
//  NightPatrolRoutine.swift
//  Nano Pet
//
//  Night patrol routine - pet patrols the territory at night.
//  Emotion: Alert → Vigilant guardian
//
//  Steps:
//  1. walking (15s) - Patrolling
//  2. sitting (6s) - Stop to observe
//  3. lookAround (9s) - Careful look around
//  4. walking (15s) - Continue patrol
//  5. climbing (12s) - Climb high to observe
//  6. lookAround (9s) - Watch from above
//  7. climbing (9s) - Climb down
//
//  Total: 75 seconds
//

import Foundation

final class NightPatrolRoutine: LinearRoutine {

    init() {
        super.init(
            name: "nightPatrol",
            priority: .normal,
            isInterruptible: true,
            emotion: "Alert → Vigilant guardian, protecting the territory",
            steps: [
                RoutineStep(
                    state: WalkingState(direction: .randomHorizontal),
                    duration: 900,  // 15 seconds
                    description: "Patrolling"
                ),
                RoutineStep(
                    state: SittingState(),
                    duration: 360,  // 6 seconds
                    description: "Stop to observe"
                ),
                RoutineStep(
                    state: LookAroundState(),
                    duration: 540,  // 9 seconds
                    description: "Careful look around"
                ),
                RoutineStep(
                    state: WalkingState(direction: .randomHorizontal),
                    duration: 900,  // 15 seconds
                    description: "Continue patrol"
                ),
                RoutineStep(
                    state: ClimbingState(wall: Bool.random() ? .left : .right, direction: .up),
                    duration: 720,  // 12 seconds
                    description: "Climb high to observe"
                ),
                RoutineStep(
                    state: LookAroundState(),
                    duration: 540,  // 9 seconds
                    description: "Watch from above"
                ),
                RoutineStep(
                    state: ClimbingState(wall: Bool.random() ? .left : .right, direction: .down),
                    duration: 540,  // 9 seconds
                    description: "Climb down"
                )
            ]
        )
    }
}
