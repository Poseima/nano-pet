//
//  TestRunner.swift
//  Dream Pet
//
//  Utility for running all tests programmatically.
//

import Foundation
import CoreGraphics

// MARK: - Test Runner

/// Utility class for running automated tests
final class TestRunner {

    /// Shared instance
    static let shared = TestRunner()

    /// Test harness
    private let harness = TestHarness()

    private init() {}

    // MARK: - Run All Tests

    /// Run all predefined test scenarios
    /// - Returns: Array of test results
    func runAllTests() -> [TestResult] {
        let scenarios = TestScenario.all
        let results = harness.runTests(scenarios)

        // Print results
        printResults(results)

        return results
    }

    /// Run a specific test scenario
    /// - Parameter scenario: Scenario to run
    /// - Returns: Test result
    func runTest(_ scenario: TestScenario) -> TestResult {
        let result = harness.runTest(scenario)
        printResult(result)
        return result
    }

    // MARK: - Print Results

    /// Print results to console
    private func printResults(_ results: [TestResult]) {
        let report = harness.generateReport(results)
        print(report)
    }

    /// Print a single result
    private func printResult(_ result: TestResult) {
        print("===== Test: \(result.scenario) =====")
        print("Result: \(result.passed ? "PASSED" : "FAILED")")
        if !result.failures.isEmpty {
            print("Failures:")
            result.failures.forEach { print("  - \($0)") }
        }
        let statesVisited = Set(result.log.map { $0.state }).sorted()
        let framesUsed = Set(result.log.map { $0.frame }).sorted()
        print("States visited: \(statesVisited)")
        print("Frames used: \(framesUsed)")
        print("")
    }

    // MARK: - Verification

    /// Verify that all tests pass
    /// - Returns: True if all tests pass
    func verifyAll() -> Bool {
        let results = runAllTests()
        let allPassed = results.allSatisfy { $0.passed }
        print("All tests passed: \(allPassed)")
        return allPassed
    }

    /// Get frame coverage across all tests
    /// - Returns: Coverage percentage
    func frameCoverage() -> Double {
        let results = runAllTests()
        let allFrames = Set(results.flatMap { $0.log.map { $0.frame } })
        return Double(allFrames.count) / Double(FrameAtlas.totalFrames) * 100
    }

    // MARK: - Quick Verification

    /// Quick verification that the system works
    /// - Returns: True if basic verification passes
    func quickVerify() -> Bool {
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
        let hasLogs = !brain.tickLog.isEmpty
        let hasStates = !brain.statesVisited.isEmpty
        let hasFrames = !brain.framesUsed.isEmpty

        print("Quick Verify:")
        print("  - Has logs: \(hasLogs)")
        print("  - Has states: \(hasStates)")
        print("  - Has frames: \(hasFrames)")
        print("  - States: \(brain.statesVisited)")
        print("  - Frames: \(brain.framesUsed)")

        return hasLogs && hasStates && hasFrames
    }
}
