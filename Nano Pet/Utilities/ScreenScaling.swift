//
//  ScreenScaling.swift
//  Nano Pet
//
//  Provides screen-size-aware scaling factors for cross-MacBook compatibility.
//  Replaces hardcoded pixel values with proportional calculations.
//

import AppKit

/// Provides screen-size-aware scaling factors
enum ScreenScaling {
    /// Reference screen height (13" MacBook Air effective resolution)
    static let referenceHeight: CGFloat = 900

    // MARK: - Screen-Aware Functions (for multi-monitor support)

    /// Get screen height for a specific screen
    /// - Parameter screen: The screen to measure, or nil to use main screen
    /// - Returns: The visible frame height of the screen
    static func screenHeight(for screen: NSScreen?) -> CGFloat {
        screen?.visibleFrame.height ?? NSScreen.main?.visibleFrame.height ?? referenceHeight
    }

    /// Get screen height for a specific point (finds which screen contains the point)
    /// - Parameter point: A point in global screen coordinates
    /// - Returns: The visible frame height of the screen containing the point
    static func screenHeight(forPoint point: CGPoint) -> CGFloat {
        let screen = NSScreen.screens.first { $0.frame.contains(point) }
        return screenHeight(for: screen)
    }

    /// Proportional detection threshold for a specific screen
    /// - Parameter screen: The screen to calculate for, or nil for main screen
    /// - Returns: 3% of screen height, minimum 30px
    static func detectionThreshold(for screen: NSScreen?) -> CGFloat {
        let height = screenHeight(for: screen)
        return max(30, height * 0.03)
    }

    /// Proportional detection threshold for a point's screen
    /// - Parameter point: A point in global screen coordinates
    /// - Returns: 3% of screen height, minimum 30px
    static func detectionThreshold(forPoint point: CGPoint) -> CGFloat {
        let height = screenHeight(forPoint: point)
        return max(30, height * 0.03)
    }

    /// Proportional window search radius for a specific screen
    /// - Parameter screen: The screen to calculate for, or nil for main screen
    /// - Returns: 10% of screen height, minimum 100px
    static func windowSearchRadius(for screen: NSScreen?) -> CGFloat {
        let height = screenHeight(for: screen)
        return max(100, height * 0.10)
    }

    /// Proportional window search radius for a point's screen
    /// - Parameter point: A point in global screen coordinates
    /// - Returns: 10% of screen height, minimum 100px
    static func windowSearchRadius(forPoint point: CGPoint) -> CGFloat {
        let height = screenHeight(forPoint: point)
        return max(100, height * 0.10)
    }

    // MARK: - Legacy Static Properties (for backward compatibility, uses main screen)

    /// Current primary screen height (legacy - prefer screen-aware functions)
    static var screenHeight: CGFloat {
        NSScreen.main?.visibleFrame.height ?? referenceHeight
    }

    /// Scale factor relative to reference (1.0 on 13" MacBook)
    static var scaleFactor: CGFloat {
        screenHeight / referenceHeight
    }

    /// Proportional detection threshold (replaces hardcoded 50)
    /// 3% of screen height, minimum 30px
    /// Note: For multi-monitor support, prefer detectionThreshold(for:) or detectionThreshold(forPoint:)
    static var detectionThreshold: CGFloat {
        max(30, screenHeight * 0.03)
    }

    /// Proportional window search radius (replaces hardcoded 150)
    /// 10% of screen height, minimum 100px
    /// Note: For multi-monitor support, prefer windowSearchRadius(for:) or windowSearchRadius(forPoint:)
    static var windowSearchRadius: CGFloat {
        max(100, screenHeight * 0.10)
    }

    // MARK: - Static Ratios (screen-independent)

    /// Sprite transparency offset ratio (0.43 of pet width = 55/128)
    /// Used for wall/ceiling offsets to compensate for transparent sprite margins
    static let spriteOffsetRatio: CGFloat = 0.43

    /// Window hold X offset ratio (0.53 of pet width = 68/128)
    static let windowHoldXRatio: CGFloat = 0.53

    /// Window hold Y offset ratio (0.35 of pet height = 45/128)
    static let windowHoldYRatio: CGFloat = 0.35
}
