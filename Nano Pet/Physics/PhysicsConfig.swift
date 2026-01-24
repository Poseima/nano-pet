//
//  PhysicsConfig.swift
//  Dream Pet
//
//  Configuration constants for physics simulation.
//

import Foundation
import CoreGraphics

// MARK: - Physics Config

/// Configuration for the physics engine
struct PhysicsConfig {
    /// Gravity acceleration (pixels per tick squared)
    var gravity: CGFloat = 0.17

    /// Maximum falling speed (pixels per tick)
    var terminalVelocity: CGFloat = 7.0

    /// Normal walking speed (pixels per tick)
    var walkSpeed: CGFloat = 0.67

    /// Running speed (pixels per tick)
    var runSpeed: CGFloat = 1.33

    /// Climbing speed (pixels per tick)
    var climbSpeed: CGFloat = 0.5

    /// Jump power (initial velocity)
    var jumpPower: CGFloat = 15.0

    /// Bounce velocity retention (0-1, 0 = no bounce)
    var bounceDecay: CGFloat = 0.5

    /// Ground friction (0-1, lower = more friction)
    var friction: CGFloat = 0.85

    /// Air resistance (0-1, lower = less resistance)
    var airResistance: CGFloat = 0.02

    /// Minimum bounce velocity
    var minBounceVelocity: CGFloat = 2.0

    /// Throw velocity multiplier
    var throwMultiplier: CGFloat = 1.5

    /// Default configuration
    static let `default` = PhysicsConfig()
}

// MARK: - Collision

/// Collision information
struct Collision: Equatable {
    let edge: Direction
    let point: CGPoint
    let normal: CGVector
}

// MARK: - Surface Type

/// Type of surface the pet is on
enum SurfaceType: Equatable {
    case floor
    case wall(Direction)
    case ceiling
    case windowTop
    case windowSide(Direction)
}

// MARK: - Motion Result

/// Result of physics simulation
struct MotionResult: Equatable {
    let newPosition: CGPoint
    let velocity: CGVector
    let collisions: [Collision]
    let surfaceType: SurfaceType?

    /// Whether there were any collisions
    var hasCollision: Bool { !collisions.isEmpty }

    /// Whether the pet landed on a surface
    var didLand: Bool {
        collisions.contains { $0.edge == .down }
    }
}
