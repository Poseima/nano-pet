//
//  SenseEngine.swift
//  Dream Pet
//
//  Gathers environmental information for decision making.
//

import Foundation
import CoreGraphics
#if os(macOS)
import AppKit
#endif

// MARK: - Sense Engine

/// Engine for perceiving the environment
final class SenseEngine {

    // MARK: - Dependencies (injected for testability)

    /// Provider for screen bounds
    var screenBoundsProvider: () -> CGRect = {
        #if os(macOS)
        NSScreen.main?.visibleFrame ?? .zero
        #else
        .zero
        #endif
    }

    /// Provider for detected windows
    var windowsProvider: () -> [WindowInfo] = { [] }

    /// Provider for cursor position
    var cursorProvider: () -> CGPoint = {
        #if os(macOS)
        NSEvent.mouseLocation
        #else
        .zero
        #endif
    }

    /// Provider for current velocity (from physics engine)
    var velocityProvider: () -> CGVector = { .zero }

    /// Provider for active window info
    var activeWindowProvider: () -> (name: String, window: WindowInfo?, didChange: Bool) = { ("", nil, false) }

    // MARK: - Input State (set by controller)

    /// Whether the pet is currently being dragged
    var isDragged: Bool = false

    /// Whether the pet was tapped (reset after reading)
    var wasTapped: Bool = false

    // MARK: - Configuration

    /// Threshold for surface detection
    var surfaceThreshold: CGFloat = 5.0

    /// Pet sprite size
    var petSize: CGSize = CGSize(width: 128, height: 128)

    // MARK: - Perception

    /// Perceive the environment from the given position
    /// - Parameter position: Current pet position (bottom-left corner)
    /// - Returns: Complete perception of the environment
    func perceive(position: CGPoint) -> Perception {
        let screen = screenBoundsProvider()
        let cursor = cursorProvider()
        let windows = windowsProvider()
        let velocity = velocityProvider()
        let activeInfo = activeWindowProvider()

        let bounds = EnvironmentBounds(
            floorY: screen.minY,
            ceilingY: screen.maxY,
            leftX: screen.minX,
            rightX: screen.maxX
        )

        // Pet frame for collision detection
        let petFrame = CGRect(x: position.x, y: position.y, width: petSize.width, height: petSize.height)
        let petCenter = CGPoint(x: position.x + petSize.width / 2, y: position.y + petSize.height / 2)

        // Surface detection
        let isOnFloor = position.y <= bounds.floorY + surfaceThreshold
        let isOnCeiling = position.y >= bounds.ceilingY - petSize.height - surfaceThreshold
        let isOnLeftWall = position.x <= bounds.leftX + surfaceThreshold
        let isOnRightWall = position.x >= bounds.rightX - petSize.width - surfaceThreshold
        let isOnWall: Direction? = isOnLeftWall ? .left : (isOnRightWall ? .right : nil)

        // Window detection
        let windowBelow = findWindowBelow(petFrame: petFrame, windows: windows)
        let isOnWindowTop = windowBelow != nil && abs(position.y - windowBelow!.topY) < surfaceThreshold
        let windowAbove = findWindowAbove(position: position, windows: windows, maxDistance: 30)

        // Nearby windows
        let nearbyWindows = windows.filter { window in
            let expandedFrame = window.frame.insetBy(dx: -50, dy: -50)
            return expandedFrame.contains(petCenter)
        }

        // Air detection
        let isInAir = !isOnFloor && !isOnCeiling && isOnWall == nil && !isOnWindowTop

        // Cursor distance
        let cursorDistance = hypot(cursor.x - petCenter.x, cursor.y - petCenter.y)

        // Reset tap after reading
        let tapped = wasTapped
        wasTapped = false

        return Perception(
            isOnFloor: isOnFloor,
            isOnWall: isOnWall,
            isOnCeiling: isOnCeiling,
            isOnWindowTop: isOnWindowTop,
            isInAir: isInAir,
            bounds: bounds,
            windowBelow: windowBelow,
            windowAbove: windowAbove,
            windowsNearby: nearbyWindows,
            activeAppName: activeInfo.name,
            activeWindow: activeInfo.window,
            activeAppDidChange: activeInfo.didChange,
            cursorPosition: cursor,
            cursorDistance: cursorDistance,
            isDragged: isDragged,
            wasTapped: tapped,
            velocity: velocity,
            petPosition: position
        )
    }

    // MARK: - Window Detection Helpers

    /// Find the window directly below the pet
    private func findWindowBelow(petFrame: CGRect, windows: [WindowInfo]) -> WindowInfo? {
        let petBottom = petFrame.minY
        let petLeft = petFrame.minX
        let petRight = petFrame.maxX

        var closestWindow: WindowInfo?
        var closestDistance: CGFloat = 50 // Max distance to detect

        for window in windows {
            // Check horizontal overlap - require at least 50% of pet width to be over window
            let overlapLeft = max(petLeft, window.leftX)
            let overlapRight = min(petRight, window.rightX)
            let overlap = overlapRight - overlapLeft

            // Require substantial overlap, not just center point
            let minOverlapRequired = petFrame.width * 0.5
            guard overlap >= minOverlapRequired else {
                continue
            }

            // Check if window top is at or below pet bottom
            let distance = petBottom - window.topY
            if distance >= -surfaceThreshold && distance < closestDistance {
                closestDistance = distance
                closestWindow = window
            }
        }

        return closestWindow
    }

    /// Find a window above the pet (for peeking)
    func findWindowAbove(position: CGPoint, windows: [WindowInfo], maxDistance: CGFloat = 150) -> WindowInfo? {
        let petCenterX = position.x + petSize.width / 2
        let petTop = position.y + petSize.height

        var closestWindow: WindowInfo?
        var closestDistance: CGFloat = maxDistance

        for window in windows {
            // Check horizontal overlap
            guard petCenterX >= window.leftX && petCenterX <= window.rightX else {
                continue
            }

            // Check if window bottom is above pet top
            let distance = window.bottomY - petTop
            if distance >= 0 && distance < closestDistance {
                closestDistance = distance
                closestWindow = window
            }
        }

        return closestWindow
    }

    /// Check if a position is on a wall edge
    func checkWallProximity(position: CGPoint, bounds: EnvironmentBounds) -> Direction? {
        if position.x <= bounds.leftX + surfaceThreshold {
            return .left
        }
        if position.x >= bounds.rightX - petSize.width - surfaceThreshold {
            return .right
        }
        return nil
    }
}
