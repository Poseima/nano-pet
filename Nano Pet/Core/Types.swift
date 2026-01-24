//
//  Types.swift
//  Dream Pet
//
//  Common type definitions for the behavior system.
//

import Foundation
import CoreGraphics

// MARK: - Frame Hint

/// Hints for frame selection
enum FrameHint: Equatable {
    case frame(Int)                         // Specific frame number
    case clip(String, direction: Direction) // Animation clip with direction
    case dragTilt(CGFloat)                  // Drag tilt based on cursor offset

    static func clip(_ name: String) -> FrameHint {
        .clip(name, direction: .left)
    }
}

// MARK: - State Context

/// Context passed to states for enter/exit
struct StateContext {
    let tick: UInt64
    let position: CGPoint
    let perception: Perception?
}

// MARK: - Tick Log Entry

/// Log entry for debugging and testing
struct TickLogEntry: Equatable {
    let tick: UInt64
    let state: String
    let frame: Int
    let position: CGPoint
    let perception: String
}

// MARK: - Test Result

/// Result of running a test scenario
struct TestResult {
    let scenario: String
    let passed: Bool
    let failures: [String]
    let log: [TickLogEntry]
}
