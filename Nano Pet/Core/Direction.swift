//
//  Direction.swift
//  Dream Pet
//
//  Direction enum for movement and orientation.
//

import Foundation

/// Primary direction enum used throughout the behavior system
enum Direction: String, CaseIterable, Equatable {
    case left
    case right
    case up
    case down

    /// Get the opposite direction
    var opposite: Direction {
        switch self {
        case .left: return .right
        case .right: return .left
        case .up: return .down
        case .down: return .up
        }
    }

    /// Random horizontal direction
    static var randomHorizontal: Direction {
        Bool.random() ? .left : .right
    }

    /// Random vertical direction
    static var randomVertical: Direction {
        Bool.random() ? .up : .down
    }

    /// Random direction (any)
    static var random: Direction {
        allCases.randomElement() ?? .left
    }

    /// Check if this is a horizontal direction
    var isHorizontal: Bool {
        self == .left || self == .right
    }

    /// Check if this is a vertical direction
    var isVertical: Bool {
        self == .up || self == .down
    }
}

/// Speed modifier for movement
enum Speed: Equatable {
    case slow
    case normal
    case run

    var multiplier: CGFloat {
        switch self {
        case .slow: return 0.5
        case .normal: return 1.0
        case .run: return 2.0
        }
    }
}

// MARK: - Compatibility

/// Compatibility typealias for existing code
typealias WalkDirection = Direction
