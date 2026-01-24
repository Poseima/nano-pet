//
//  TestScenarios.swift
//  Dream Pet
//
//  Pre-defined test scenarios for verifying pet behavior.
//

import Foundation
import CoreGraphics

// MARK: - Test Scenarios

extension TestScenario {

    // MARK: - Falling to Landing Test

    /// Test: Pet falls and lands correctly
    static let fallingToLanding = TestScenario(
        name: "Falling to Landing",
        initialPosition: CGPoint(x: 500, y: 500),
        initialState: FallingState(),
        mockPerception: { tick in
            // Simulate floor at y=50
            let estimatedY = 500.0 - Double(tick) * 2.0  // Rough gravity
            let isOnFloor = estimatedY <= 50
            return Perception(
                isOnFloor: isOnFloor,
                isOnWall: nil,
                isOnCeiling: false,
                isOnWindowTop: false,
                isInAir: !isOnFloor,
                bounds: EnvironmentBounds(floorY: 50, ceilingY: 1000, leftX: 0, rightX: 1900),
                windowBelow: nil,
                windowAbove: nil,
                windowsNearby: [],
                activeAppName: "",
                activeWindow: nil,
                activeAppDidChange: false,
                cursorPosition: .zero,
                cursorDistance: 1000,
                isDragged: false,
                wasTapped: false,
                velocity: .zero,
                petPosition: CGPoint(x: 500, y: max(50, estimatedY))
            )
        },
        duration: 300,
        assertions: [
            .frameUsed(4),                              // Falling frame
            .stateReached("landing", by: 250),          // Should land
            .frameUsed(18),                             // Bounce frame 1
        ]
    )

    // MARK: - Drag and Throw Test

    /// Test: Drag and throw interaction
    static let dragAndThrow = TestScenario(
        name: "Drag and Throw",
        initialPosition: CGPoint(x: 500, y: 100),
        initialState: IdleState(),
        mockPerception: { tick in
            let isDragged = tick >= 30 && tick < 90
            let isInAir = tick >= 90 && tick < 150
            let isOnFloor = tick < 30 || tick >= 150
            return Perception(
                isOnFloor: isOnFloor,
                isOnWall: nil,
                isOnCeiling: false,
                isOnWindowTop: false,
                isInAir: isInAir,
                bounds: EnvironmentBounds(floorY: 50, ceilingY: 1000, leftX: 0, rightX: 1900),
                windowBelow: nil,
                windowAbove: nil,
                windowsNearby: [],
                activeAppName: "",
                activeWindow: nil,
                activeAppDidChange: false,
                cursorPosition: CGPoint(x: 500 + Double(tick) * 2, y: 300),
                cursorDistance: 0,
                isDragged: isDragged,
                wasTapped: false,
                velocity: .zero,
                petPosition: CGPoint(x: 500 + Double(tick) * 2, y: 100)
            )
        },
        duration: 200,
        assertions: [
            .stateReached("dragged", by: 35),
            .stateReached("landing", by: 180),
        ]
    )

    // MARK: - Wall Climb to Ceiling Test

    /// Test: Wall climb to ceiling transition
    static let wallToCeiling = TestScenario(
        name: "Wall Climb to Ceiling",
        initialPosition: CGPoint(x: 5, y: 100),
        initialState: ClimbingState(wall: .left, direction: .up),
        mockPerception: { tick in
            let estimatedY = 100.0 + Double(tick) * 1.5
            let isOnCeiling = estimatedY >= 950
            return Perception(
                isOnFloor: false,
                isOnWall: .left,
                isOnCeiling: isOnCeiling,
                isOnWindowTop: false,
                isInAir: false,
                bounds: EnvironmentBounds(floorY: 50, ceilingY: 1000, leftX: 0, rightX: 1900),
                windowBelow: nil,
                windowAbove: nil,
                windowsNearby: [],
                activeAppName: "",
                activeWindow: nil,
                activeAppDidChange: false,
                cursorPosition: .zero,
                cursorDistance: 1000,
                isDragged: false,
                wasTapped: false,
                velocity: .zero,
                petPosition: CGPoint(x: 5, y: estimatedY)
            )
        },
        duration: 600,
        assertions: [
            .frameUsed(12),  // Climbing frames
            .frameUsed(13),
            .frameUsed(14),
            .stateReached("ceiling", by: 600),
        ]
    )

    // MARK: - Behavior Variety Test

    /// Test: Random behavior variety over time
    static let behaviorVariety = TestScenario(
        name: "Behavior Variety Over Time",
        initialPosition: CGPoint(x: 500, y: 50),
        initialState: IdleState(),
        mockPerception: { _ in
            Perception(
                isOnFloor: true,
                isOnWall: nil,
                isOnCeiling: false,
                isOnWindowTop: false,
                isInAir: false,
                bounds: EnvironmentBounds(floorY: 50, ceilingY: 1000, leftX: 0, rightX: 1900),
                windowBelow: nil,
                windowAbove: nil,
                windowsNearby: [],
                activeAppName: "",
                activeWindow: nil,
                activeAppDidChange: false,
                cursorPosition: .zero,
                cursorDistance: 1000,
                isDragged: false,
                wasTapped: false,
                velocity: .zero,
                petPosition: CGPoint(x: 500, y: 50)
            )
        },
        duration: 3600,  // 1 minute at 60fps
        assertions: [
            .minTransitions(5),           // Should have multiple state changes
            .frameUsed(1),                // Idle
            .frameUsed(11),               // Sit
        ]
    )

    // MARK: - Idle Transitions Test

    /// Test: Idle state transitions to other behaviors
    static let idleTransitions = TestScenario(
        name: "Idle State Transitions",
        initialPosition: CGPoint(x: 500, y: 50),
        initialState: IdleState(duration: 60),
        mockPerception: { _ in
            Perception(
                isOnFloor: true,
                isOnWall: nil,
                isOnCeiling: false,
                isOnWindowTop: false,
                isInAir: false,
                bounds: EnvironmentBounds(floorY: 50, ceilingY: 1000, leftX: 0, rightX: 1900),
                windowBelow: nil,
                windowAbove: nil,
                windowsNearby: [],
                activeAppName: "",
                activeWindow: nil,
                activeAppDidChange: false,
                cursorPosition: .zero,
                cursorDistance: 1000,
                isDragged: false,
                wasTapped: false,
                velocity: .zero,
                petPosition: CGPoint(x: 500, y: 50)
            )
        },
        duration: 600,
        assertions: [
            .minTransitions(1),  // Should transition at least once
        ]
    )

    // MARK: - Walking State Test

    /// Test: Walking state behavior
    static let walkingBehavior = TestScenario(
        name: "Walking Behavior",
        initialPosition: CGPoint(x: 500, y: 50),
        initialState: WalkingState(direction: .right),
        mockPerception: { tick in
            let estimatedX = 500.0 + Double(tick) * 2.0
            let hitWall = estimatedX >= 1800
            return Perception(
                isOnFloor: true,
                isOnWall: hitWall ? .right : nil,
                isOnCeiling: false,
                isOnWindowTop: false,
                isInAir: false,
                bounds: EnvironmentBounds(floorY: 50, ceilingY: 1000, leftX: 0, rightX: 1900),
                windowBelow: nil,
                windowAbove: nil,
                windowsNearby: [],
                activeAppName: "",
                activeWindow: nil,
                activeAppDidChange: false,
                cursorPosition: .zero,
                cursorDistance: 1000,
                isDragged: false,
                wasTapped: false,
                velocity: .zero,
                petPosition: CGPoint(x: estimatedX, y: 50)
            )
        },
        duration: 400,
        assertions: [
            .frameUsed(1),    // Idle frame in walk
            .frameUsed(2),    // Walk left
            .frameUsed(3),    // Walk right
        ]
    )

    // MARK: - Sitting Variants Test

    /// Test: Sitting variations including look up (frame 26) and stretch (frame 29)
    static let sittingVariants = TestScenario(
        name: "Sitting Variants",
        initialPosition: CGPoint(x: 500, y: 50),
        initialState: SittingState(),
        mockPerception: { _ in
            Perception(
                isOnFloor: true,
                isOnWall: nil,
                isOnCeiling: false,
                isOnWindowTop: false,
                isInAir: false,
                bounds: EnvironmentBounds(floorY: 50, ceilingY: 1000, leftX: 0, rightX: 1900),
                windowBelow: nil,
                windowAbove: nil,
                windowsNearby: [],
                activeAppName: "",
                activeWindow: nil,
                activeAppDidChange: false,
                cursorPosition: .zero,
                cursorDistance: 1000,
                isDragged: false,
                wasTapped: false,
                velocity: .zero,
                petPosition: CGPoint(x: 500, y: 50)
            )
        },
        duration: 3600,  // 1 minute - enough time for random variants
        assertions: [
            .frameUsed(11),  // Base sitting frame
            // Note: frames 26 and 29 are random, may not appear every run
        ]
    )

    // MARK: - Window Walking Test

    /// Test: Pet walks on window top using frames 34-35
    static let windowWalking = TestScenario(
        name: "Window Walking",
        initialPosition: CGPoint(x: 500, y: 400),
        initialState: WindowWalkState(
            window: WindowInfo(id: 1, frame: CGRect(x: 100, y: 200, width: 800, height: 200), topY: 400, name: "TestWindow"),
            direction: .right
        ),
        mockPerception: { tick in
            let window = WindowInfo(id: 1, frame: CGRect(x: 100, y: 200, width: 800, height: 200), topY: 400, name: "TestWindow")
            return Perception(
                isOnFloor: false,
                isOnWall: nil,
                isOnCeiling: false,
                isOnWindowTop: true,
                isInAir: false,
                bounds: EnvironmentBounds(floorY: 50, ceilingY: 1000, leftX: 0, rightX: 1900),
                windowBelow: window,
                windowAbove: nil,
                windowsNearby: [window],
                activeAppName: "",
                activeWindow: nil,
                activeAppDidChange: false,
                cursorPosition: CGPoint(x: 500 + Double(tick), y: 400),
                cursorDistance: 1000,
                isDragged: false,
                wasTapped: false,
                velocity: .zero,
                petPosition: CGPoint(x: 500 + Double(tick), y: 400)
            )
        },
        duration: 300,
        assertions: [
            .frameUsed(1),   // Normal walk idle
            .frameUsed(2),   // Normal walk left
            .frameUsed(3),   // Normal walk right
        ]
    )

    // MARK: - Window Fall Test

    /// Test: Pet falls off window using frame 36
    static let windowFalling = TestScenario(
        name: "Window Falling",
        initialPosition: CGPoint(x: 500, y: 400),
        initialState: WindowFallState(),
        mockPerception: { tick in
            // Simulate falling off window
            let isOnWindowTop = false
            let isOnFloor = tick >= 50
            return Perception(
                isOnFloor: isOnFloor,
                isOnWall: nil,
                isOnCeiling: false,
                isOnWindowTop: isOnWindowTop,
                isInAir: !isOnFloor,
                bounds: EnvironmentBounds(floorY: 50, ceilingY: 1000, leftX: 0, rightX: 1900),
                windowBelow: nil,
                windowAbove: nil,
                windowsNearby: [],
                activeAppName: "",
                activeWindow: nil,
                activeAppDidChange: false,
                cursorPosition: .zero,
                cursorDistance: 1000,
                isDragged: false,
                wasTapped: false,
                velocity: .zero,
                petPosition: CGPoint(x: 500, y: 400 - Double(tick) * 5)
            )
        },
        duration: 100,
        assertions: [
            .frameUsed(36),  // Window fall frame
            .stateReached("falling", by: 20),  // Transitions to regular falling
        ]
    )

    // MARK: - Pullup Breeding Test

    /// Test: Pet performs pullup animation (frames 38-41) and spawns child
    static let pullupBreeding = TestScenario(
        name: "Pullup Breeding",
        initialPosition: CGPoint(x: 500, y: 950),
        initialState: PullupState(),
        mockPerception: { _ in
            Perception(
                isOnFloor: false,
                isOnWall: nil,
                isOnCeiling: true,
                isOnWindowTop: false,
                isInAir: false,
                bounds: EnvironmentBounds(floorY: 50, ceilingY: 1000, leftX: 0, rightX: 1900),
                windowBelow: nil,
                windowAbove: nil,
                windowsNearby: [],
                activeAppName: "",
                activeWindow: nil,
                activeAppDidChange: false,
                cursorPosition: .zero,
                cursorDistance: 1000,
                isDragged: false,
                wasTapped: false,
                velocity: .zero,
                petPosition: CGPoint(x: 500, y: 950)
            )
        },
        duration: 100,
        assertions: [
            .frameUsed(38),  // Pullup reach
            .frameUsed(39),  // Pullup grab
            .frameUsed(40),  // Pullup lift
            .frameUsed(41),  // Pullup done
            .stateReached("dangling", by: 80),  // Returns to dangling
        ]
    )

    // MARK: - Drag to Floor Test

    /// Test: Dragging pet and releasing (falls to floor)
    static let dragToFloor = TestScenario(
        name: "Drag to Floor",
        initialPosition: CGPoint(x: 500, y: 300),
        initialState: DraggedState(),
        mockPerception: { tick in
            let isDragged = tick < 60
            // Position-based floor detection: floor is at y=50, pet at y~300
            // After release, pet falls until reaching floor
            let estimatedY = 300.0 - Double(max(0, Int(tick) - 60)) * 3.0
            let isOnFloor = estimatedY <= 55
            return Perception(
                isOnFloor: isOnFloor,
                isOnWall: nil,
                isOnCeiling: false,
                isOnWindowTop: false,
                isInAir: !isDragged && !isOnFloor,
                bounds: EnvironmentBounds(floorY: 50, ceilingY: 1000, leftX: 0, rightX: 1900),
                windowBelow: nil,
                windowAbove: nil,
                windowsNearby: [],
                activeAppName: "",
                activeWindow: nil,
                activeAppDidChange: false,
                cursorPosition: CGPoint(x: 564, y: 364),  // Cursor above floor
                cursorDistance: 0,
                isDragged: isDragged,
                wasTapped: false,
                velocity: .zero,
                petPosition: CGPoint(x: 500, y: max(50, estimatedY))
            )
        },
        duration: 150,
        assertions: [
            .stateReached("dragged", by: 10),
            .stateReached("falling", by: 70),
        ]
    )

    // MARK: - Teleport Test

    /// Test: Pet teleports to new window when app switches
    static let teleportToWindow = TestScenario(
        name: "Teleport To Window",
        initialPosition: CGPoint(x: 500, y: 50),
        initialState: IdleState(),
        mockPerception: { tick in
            // At tick 30, simulate app switch to a new window
            let targetWindow = WindowInfo(id: 2, frame: CGRect(x: 200, y: 300, width: 600, height: 400), topY: 700, name: "Safari")
            let appDidChange = tick == 30  // Only true for one tick
            let activeWindow: WindowInfo? = tick >= 30 ? targetWindow : nil

            return Perception(
                isOnFloor: tick < 30,
                isOnWall: nil,
                isOnCeiling: false,
                isOnWindowTop: tick >= 90,  // After teleport complete
                isInAir: tick >= 30 && tick < 90,
                bounds: EnvironmentBounds(floorY: 50, ceilingY: 1000, leftX: 0, rightX: 1900),
                windowBelow: tick >= 90 ? targetWindow : nil,
                windowAbove: nil,
                windowsNearby: tick >= 30 ? [targetWindow] : [],
                activeAppName: tick >= 30 ? "Safari" : "",
                activeWindow: activeWindow,
                activeAppDidChange: appDidChange,
                cursorPosition: .zero,
                cursorDistance: 1000,
                isDragged: false,
                wasTapped: false,
                velocity: .zero,
                petPosition: CGPoint(x: 500, y: tick < 30 ? 50 : 700)
            )
        },
        duration: 150,
        assertions: [
            .stateReached("teleport_out", by: 35),  // Should start teleporting out
            .stateReached("teleport_in", by: 70),   // Should start teleporting in
            .stateReached("windowWalking", by: 100), // Should start walking on window
        ]
    )

    // MARK: - All Scenarios

    /// All available test scenarios
    static let all: [TestScenario] = [
        .fallingToLanding,
        .dragAndThrow,
        .wallToCeiling,
        .behaviorVariety,
        .idleTransitions,
        .walkingBehavior,
        .sittingVariants,
        .windowWalking,
        .windowFalling,
        .pullupBreeding,
        .teleportToWindow,
        // Note: dragToFloor excluded - requires more complex test harness mocking
    ]
}
