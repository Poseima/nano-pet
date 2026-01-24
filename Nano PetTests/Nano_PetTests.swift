//
//  Nano_PetTests.swift
//  Nano PetTests
//
//  Created by MRS on 2025/12/27.
//

import Testing
import Foundation
import CoreGraphics
@testable import Nano_Pet

@MainActor
struct Nano_PetTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    // MARK: - PetBrain Simulation Tests

    @Test func testPetBrainQuickVerify() async throws {
        // Create a brain and run for a few ticks
        let brain = PetBrain()
        brain.enableLogging = true

        // Set up mock perception
        brain.senseEngine.screenBoundsProvider = {
            CGRect(x: 0, y: 0, width: 1920, height: 1080)
        }

        // Run 100 ticks
        for _ in 0..<100 {
            brain.tick()
        }

        // Verify basic functionality
        #expect(!brain.tickLog.isEmpty, "Should have tick logs")
        #expect(!brain.statesVisited.isEmpty, "Should have visited states")
        #expect(!brain.framesUsed.isEmpty, "Should have used frames")

        print("Quick Verify Results:")
        print("  - Tick count: \(brain.tickCount)")
        print("  - States visited: \(brain.statesVisited)")
        print("  - Frames used: \(brain.framesUsed)")
    }

    @Test func testFallingToLanding() async throws {
        let harness = TestHarness()
        let result = harness.runTest(.fallingToLanding)

        #expect(result.passed, "Falling to landing test should pass. Failures: \(result.failures)")

        print("Falling to Landing Results:")
        print("  - States visited: \(Set(result.log.map { $0.state }))")
        print("  - Frames used: \(Set(result.log.map { $0.frame }))")
    }

    @Test func testDragAndThrow() async throws {
        let harness = TestHarness()
        let result = harness.runTest(.dragAndThrow)

        #expect(result.passed, "Drag and throw test should pass. Failures: \(result.failures)")

        print("Drag and Throw Results:")
        print("  - States visited: \(Set(result.log.map { $0.state }))")
    }

    @Test func testWallToCeiling() async throws {
        let harness = TestHarness()
        let result = harness.runTest(.wallToCeiling)

        #expect(result.passed, "Wall to ceiling test should pass. Failures: \(result.failures)")

        print("Wall to Ceiling Results:")
        print("  - States visited: \(Set(result.log.map { $0.state }))")
        print("  - Frames used: \(Set(result.log.map { $0.frame }))")
    }

    @Test func testBehaviorVariety() async throws {
        let harness = TestHarness()
        let result = harness.runTest(.behaviorVariety)

        #expect(result.passed, "Behavior variety test should pass. Failures: \(result.failures)")

        let statesVisited = Set(result.log.map { $0.state })
        print("Behavior Variety Results:")
        print("  - States visited (\(statesVisited.count)): \(statesVisited)")
    }

    @Test func testIdleTransitions() async throws {
        let harness = TestHarness()
        let result = harness.runTest(.idleTransitions)

        #expect(result.passed, "Idle transitions test should pass. Failures: \(result.failures)")
    }

    @Test func testWalkingBehavior() async throws {
        let harness = TestHarness()
        let result = harness.runTest(.walkingBehavior)

        #expect(result.passed, "Walking behavior test should pass. Failures: \(result.failures)")

        print("Walking Behavior Results:")
        print("  - Frames used: \(Set(result.log.map { $0.frame }))")
    }

    @Test func testAllScenarios() async throws {
        let harness = TestHarness()
        let results = harness.runTests(TestScenario.all)

        let passedCount = results.filter { $0.passed }.count
        let totalCount = results.count

        print("\n===== All Tests Summary =====")
        print("Passed: \(passedCount)/\(totalCount)")

        for result in results {
            print("[\(result.passed ? "PASS" : "FAIL")] \(result.scenario)")
            if !result.failures.isEmpty {
                for failure in result.failures {
                    print("  - \(failure)")
                }
            }
        }

        #expect(passedCount == totalCount, "All \(totalCount) tests should pass, but only \(passedCount) passed")
    }

    @Test func testFrameCoverage() async throws {
        let harness = TestHarness()
        let results = harness.runTests(TestScenario.all)

        let allFrames = Set(results.flatMap { $0.log.map { $0.frame } })
        let coverage = Double(allFrames.count) / Double(FrameAtlas.totalFrames) * 100

        print("Frame Coverage: \(String(format: "%.1f", coverage))%")
        print("Frames used: \(allFrames.sorted())")

        #expect(coverage >= 20, "Frame coverage should be at least 20%, got \(coverage)%")
    }

    // MARK: - New Frame Orchestration Tests

    @Test func testSittingVariants() async throws {
        let harness = TestHarness()
        let result = harness.runTest(.sittingVariants)

        #expect(result.passed, "Sitting variants test should pass. Failures: \(result.failures)")

        let framesUsed = Set(result.log.map { $0.frame })
        let statesVisited = Set(result.log.map { $0.state })
        print("Sitting Variants Results:")
        print("  - States visited: \(statesVisited)")
        print("  - Frames used: \(framesUsed.sorted())")

        // Check if variant states were reached (may be random)
        if statesVisited.contains("sitLookUp") {
            print("  - SitLookUpState was triggered (frame 26)")
        }
        if statesVisited.contains("sitStretch") {
            print("  - SitStretchState was triggered (frame 29)")
        }
    }

    @Test func testWindowWalking() async throws {
        let harness = TestHarness()
        let result = harness.runTest(.windowWalking)

        #expect(result.passed, "Window walking test should pass. Failures: \(result.failures)")

        let framesUsed = Set(result.log.map { $0.frame })
        print("Window Walking Results:")
        print("  - Frames used: \(framesUsed.sorted())")
        #expect(framesUsed.contains(34), "Should use frame 34 for window walking")
        #expect(framesUsed.contains(35), "Should use frame 35 for window walking")
    }

    @Test func testWindowFalling() async throws {
        let harness = TestHarness()
        let result = harness.runTest(.windowFalling)

        #expect(result.passed, "Window falling test should pass. Failures: \(result.failures)")

        let framesUsed = Set(result.log.map { $0.frame })
        let statesVisited = Set(result.log.map { $0.state })
        print("Window Falling Results:")
        print("  - States visited: \(statesVisited)")
        print("  - Frames used: \(framesUsed.sorted())")
        #expect(framesUsed.contains(36), "Should use frame 36 for window falling")
    }

    @Test func testPullupBreeding() async throws {
        let harness = TestHarness()
        let result = harness.runTest(.pullupBreeding)

        #expect(result.passed, "Pullup breeding test should pass. Failures: \(result.failures)")

        let framesUsed = Set(result.log.map { $0.frame })
        print("Pullup Breeding Results:")
        print("  - Frames used: \(framesUsed.sorted())")
        #expect(framesUsed.contains(38), "Should use frame 38 for pullup")
        #expect(framesUsed.contains(39), "Should use frame 39 for pullup")
        #expect(framesUsed.contains(40), "Should use frame 40 for pullup")
        #expect(framesUsed.contains(41), "Should use frame 41 for pullup")
    }

    @Test func testTeleportToWindow() async throws {
        let harness = TestHarness()
        let result = harness.runTest(.teleportToWindow)

        #expect(result.passed, "Teleport to window test should pass. Failures: \(result.failures)")

        let statesVisited = Set(result.log.map { $0.state })
        print("Teleport To Window Results:")
        print("  - States visited: \(statesVisited)")

        #expect(statesVisited.contains("teleport_out"), "Should have entered teleport_out state")
        #expect(statesVisited.contains("teleport_in"), "Should have entered teleport_in state")
    }

    @Test func testNewFrameCoverage() async throws {
        let harness = TestHarness()

        // Run all new orchestration tests
        let newTests: [TestScenario] = [
            .sittingVariants,
            .windowWalking,
            .windowFalling,
            .pullupBreeding,
        ]

        let results = harness.runTests(newTests)
        let allFrames = Set(results.flatMap { $0.log.map { $0.frame } })

        print("\n===== New Frame Orchestration Coverage =====")
        print("Frames from new tests: \(allFrames.sorted())")

        // Check for the new frames
        let newFrames = [26, 29, 34, 35, 36, 38, 39, 40, 41]
        var coveredNew: [Int] = []
        var missingNew: [Int] = []

        for frame in newFrames {
            if allFrames.contains(frame) {
                coveredNew.append(frame)
            } else {
                missingNew.append(frame)
            }
        }

        print("New frames covered: \(coveredNew)")
        print("New frames missing: \(missingNew)")

        // Frames 26 and 29 are random, so we only require the deterministic ones
        let requiredFrames = [34, 35, 36, 38, 39, 40, 41]
        for frame in requiredFrames {
            #expect(allFrames.contains(frame), "Frame \(frame) should be covered by new tests")
        }
    }
}
