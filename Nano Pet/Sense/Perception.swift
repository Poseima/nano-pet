//
//  Perception.swift
//  Dream Pet
//
//  Perception data structures for environmental sensing.
//

import Foundation
import CoreGraphics

// MARK: - Environment Bounds

/// Bounds of the environment (screen or container)
struct EnvironmentBounds: Equatable {
    let floorY: CGFloat
    let ceilingY: CGFloat
    let leftX: CGFloat
    let rightX: CGFloat

    /// Total width
    var width: CGFloat { rightX - leftX }

    /// Total height
    var height: CGFloat { ceilingY - floorY }

    /// Center point
    var center: CGPoint {
        CGPoint(x: leftX + width / 2, y: floorY + height / 2)
    }

    /// Default empty bounds
    static let zero = EnvironmentBounds(floorY: 0, ceilingY: 0, leftX: 0, rightX: 0)
}

// MARK: - Window Info

/// Information about a detected window
struct WindowInfo: Equatable, Identifiable {
    let id: Int
    let frame: CGRect
    let topY: CGFloat
    let name: String

    /// Bottom Y coordinate
    var bottomY: CGFloat { frame.minY }

    /// Left X coordinate
    var leftX: CGFloat { frame.minX }

    /// Right X coordinate
    var rightX: CGFloat { frame.maxX }

    /// Width
    var width: CGFloat { frame.width }

    /// Height
    var height: CGFloat { frame.height }
}

// MARK: - Perception

/// Complete perception of the environment at a given moment
struct Perception: Equatable {
    // Surface detection
    let isOnFloor: Bool
    let isOnWall: Direction?
    let isOnCeiling: Bool
    let isOnWindowTop: Bool
    let isInAir: Bool

    // Environment bounds
    let bounds: EnvironmentBounds

    // Windows
    let windowBelow: WindowInfo?
    let windowAbove: WindowInfo?  // Window above pet (for grabbing bottom edge)
    let windowsNearby: [WindowInfo]

    // Active window awareness
    let activeAppName: String
    let activeWindow: WindowInfo?
    let activeAppDidChange: Bool  // True when user just switched apps

    // Cursor
    let cursorPosition: CGPoint
    let cursorDistance: CGFloat

    // User input
    let isDragged: Bool
    let wasTapped: Bool

    // Physics state
    let velocity: CGVector

    // Pet position
    let petPosition: CGPoint

    // Summary for logging
    var summary: String {
        var parts: [String] = []
        if isOnFloor { parts.append("floor") }
        if let wall = isOnWall { parts.append("wall-\(wall.rawValue)") }
        if isOnCeiling { parts.append("ceiling") }
        if isOnWindowTop { parts.append("window-top") }
        if isInAir { parts.append("air") }
        if isDragged { parts.append("dragged") }
        return parts.isEmpty ? "none" : parts.joined(separator: ",")
    }

    /// Default empty perception
    static let empty = Perception(
        isOnFloor: false,
        isOnWall: nil,
        isOnCeiling: false,
        isOnWindowTop: false,
        isInAir: true,
        bounds: .zero,
        windowBelow: nil,
        windowAbove: nil,
        windowsNearby: [],
        activeAppName: "",
        activeWindow: nil,
        activeAppDidChange: false,
        cursorPosition: .zero,
        cursorDistance: 0,
        isDragged: false,
        wasTapped: false,
        velocity: .zero,
        petPosition: .zero
    )
}
