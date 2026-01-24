//
//  TestHarness.swift
//  Dream Pet
//
//  Testing framework for running simulations and verifying behavior.
//

import Foundation
import CoreGraphics

// MARK: - Test Assertion

/// Types of assertions that can be made about pet behavior
enum TestAssertion {
    /// State with given name was reached by the specified tick
    case stateReached(String, by: Int)

    /// Frame number was displayed at some point
    case frameUsed(Int)

    /// Position was within rect at specified tick
    case positionInRange(CGRect, at: Int)

    /// State was never entered
    case stateNeverReached(String)

    /// Transition from one state to another occurred
    case transitionOccurred(from: String, to: String)

    /// Minimum number of state transitions occurred
    case minTransitions(Int)

    /// Frame coverage percentage achieved
    case frameCoverage(minPercent: Double)
}

// MARK: - Test Scenario

/// A complete test scenario with setup, simulation, and assertions
struct TestScenario {
    /// Name of the scenario
    let name: String

    /// Initial position of the pet
    let initialPosition: CGPoint

    /// Initial state of the pet
    let initialState: any PetState

    /// Function that generates perception for each tick
    let mockPerception: (UInt64) -> Perception

    /// Duration of the simulation in ticks
    let duration: Int

    /// Assertions to check after simulation
    let assertions: [TestAssertion]
}

// MARK: - Test Harness

/// Harness for running automated tests on the pet behavior system
final class TestHarness {

    // MARK: - Run Test

    /// Run a single test scenario
    /// - Parameter scenario: The scenario to run
    /// - Returns: Test result with pass/fail status and details
    func runTest(_ scenario: TestScenario) -> TestResult {
        let brain = PetBrain()
        brain.enableLogging = true
        brain.setPosition(scenario.initialPosition)
        brain.stateEngine.forceState(scenario.initialState)

        // Inject mock screen bounds
        brain.senseEngine.screenBoundsProvider = {
            CGRect(x: 0, y: 0, width: 1920, height: 1080)
        }

        // Track perception for injection
        var currentMockPerception: Perception = .empty

        // Run simulation
        for tick in 0..<UInt64(scenario.duration) {
            // Generate mock perception for this tick
            currentMockPerception = scenario.mockPerception(tick)

            // Inject mock input states
            brain.senseEngine.isDragged = currentMockPerception.isDragged
            brain.senseEngine.wasTapped = currentMockPerception.wasTapped

            // Override perception providers for this tick
            let mockBounds = currentMockPerception.bounds
            brain.senseEngine.screenBoundsProvider = {
                CGRect(x: mockBounds.leftX, y: mockBounds.floorY,
                       width: mockBounds.rightX - mockBounds.leftX,
                       height: mockBounds.ceilingY - mockBounds.floorY)
            }

            // Set up windows provider if mock perception has windows
            let mockWindows = currentMockPerception.windowsNearby
            if !mockWindows.isEmpty {
                brain.senseEngine.windowsProvider = { mockWindows }
            }

            // Set up active window provider for teleport testing
            let activeAppName = currentMockPerception.activeAppName
            let activeWindow = currentMockPerception.activeWindow
            let activeAppDidChange = currentMockPerception.activeAppDidChange
            brain.senseEngine.activeWindowProvider = {
                (name: activeAppName, window: activeWindow, didChange: activeAppDidChange)
            }

            brain.tick()
        }

        // Check assertions
        var failures: [String] = []

        for assertion in scenario.assertions {
            switch assertion {
            case .stateReached(let stateName, let byTick):
                let reached = brain.tickLog.first { $0.state == stateName && $0.tick <= UInt64(byTick) }
                if reached == nil {
                    failures.append("State '\(stateName)' not reached by tick \(byTick)")
                }

            case .frameUsed(let frame):
                let used = brain.tickLog.contains { $0.frame == frame }
                if !used {
                    failures.append("Frame \(frame) was never used")
                }

            case .positionInRange(let rect, let atTick):
                if let entry = brain.tickLog.first(where: { $0.tick == UInt64(atTick) }) {
                    if !rect.contains(entry.position) {
                        failures.append("Position \(entry.position) not in \(rect) at tick \(atTick)")
                    }
                } else {
                    failures.append("No log entry found at tick \(atTick)")
                }

            case .stateNeverReached(let stateName):
                let reached = brain.tickLog.contains { $0.state == stateName }
                if reached {
                    failures.append("State '\(stateName)' was reached but shouldn't have been")
                }

            case .transitionOccurred(let from, let to):
                var found = false
                for i in 1..<brain.tickLog.count {
                    if brain.tickLog[i-1].state == from && brain.tickLog[i].state == to {
                        found = true
                        break
                    }
                }
                if !found {
                    failures.append("Transition from '\(from)' to '\(to)' never occurred")
                }

            case .minTransitions(let count):
                var transitions = 0
                for i in 1..<brain.tickLog.count {
                    if brain.tickLog[i].state != brain.tickLog[i-1].state {
                        transitions += 1
                    }
                }
                if transitions < count {
                    failures.append("Only \(transitions) transitions occurred, expected at least \(count)")
                }

            case .frameCoverage(let minPercent):
                let uniqueFrames = Set(brain.tickLog.map { $0.frame }).count
                let coverage = Double(uniqueFrames) / Double(FrameAtlas.totalFrames) * 100
                if coverage < minPercent {
                    failures.append("Frame coverage \(String(format: "%.1f", coverage))% below minimum \(minPercent)%")
                }
            }
        }

        return TestResult(
            scenario: scenario.name,
            passed: failures.isEmpty,
            failures: failures,
            log: brain.tickLog
        )
    }

    // MARK: - Run Multiple Tests

    /// Run multiple test scenarios
    /// - Parameter scenarios: Array of scenarios to run
    /// - Returns: Array of test results
    func runTests(_ scenarios: [TestScenario]) -> [TestResult] {
        scenarios.map { runTest($0) }
    }

    // MARK: - Report Generation

    /// Generate a summary report of test results
    /// - Parameter results: Array of test results
    /// - Returns: Human-readable report string
    func generateReport(_ results: [TestResult]) -> String {
        var report = "===== Test Report =====\n"
        report += "Total tests: \(results.count)\n"
        report += "Passed: \(results.filter { $0.passed }.count)\n"
        report += "Failed: \(results.filter { !$0.passed }.count)\n\n"

        for result in results {
            report += "[\(result.passed ? "PASS" : "FAIL")] \(result.scenario)\n"
            if !result.failures.isEmpty {
                for failure in result.failures {
                    report += "  - \(failure)\n"
                }
            }
            let statesVisited = Set(result.log.map { $0.state })
            let framesUsed = Set(result.log.map { $0.frame })
            report += "  States: \(statesVisited.sorted().joined(separator: ", "))\n"
            report += "  Frames: \(framesUsed.sorted().map { String($0) }.joined(separator: ", "))\n"
            report += "\n"
        }

        return report
    }
}
