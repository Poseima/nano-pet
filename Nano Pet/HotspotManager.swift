//
//  HotspotManager.swift
//  Nano Pet
//
//  Manages clickable regions on pet sprites that trigger behaviors
//

import Foundation
import CoreGraphics

// MARK: - Hotspot

/// A clickable region on a pet sprite
struct Hotspot {
    let rect: CGRect           // Region in sprite coordinate space (128x128)
    let behavior: String       // Behavior to trigger on tap
    let condition: String?     // Optional condition for showing hotspot

    init(rect: CGRect, behavior: String, condition: String? = nil) {
        self.rect = rect
        self.behavior = behavior
        self.condition = condition
    }
}

// MARK: - Hotspot Manager

/// Manages hotspots for a pet and performs hit testing
class HotspotManager {
    /// Current hotspots
    private var hotspots: [Hotspot] = []

    /// Pet name for this manager
    private let petName: String

    /// Sprite size (default 128x128)
    private let spriteSize: CGSize

    init(petName: String, spriteSize: CGSize = CGSize(width: 128, height: 128)) {
        self.petName = petName
        self.spriteSize = spriteSize
        loadHotspots()
    }

    // MARK: - Loading

    /// Load hotspots from config
    /// TODO: Implement loading from animation config when AnimationConfigLoader is available
    private func loadHotspots() {
        // Hotspots are loaded manually via setHotspots() or from Shimeji XML
        // Default to no hotspots until explicitly set
    }

    /// Reload hotspots from config
    func reload() {
        hotspots.removeAll()
        loadHotspots()
    }

    /// Set hotspots directly
    func setHotspots(_ newHotspots: [Hotspot]) {
        hotspots = newHotspots
    }

    /// Add a hotspot
    func addHotspot(_ hotspot: Hotspot) {
        hotspots.append(hotspot)
    }

    /// Remove hotspots for a behavior
    func removeHotspots(for behavior: String) {
        hotspots.removeAll { $0.behavior == behavior }
    }

    /// Clear all hotspots
    func clearHotspots() {
        hotspots.removeAll()
    }

    // MARK: - Hit Testing

    /// Test if a point hits any hotspot
    /// - Parameters:
    ///   - point: Point in sprite coordinate space (0,0 is bottom-left)
    ///   - flipped: Whether the sprite is horizontally flipped
    /// - Returns: The hotspot that was hit, or nil
    func hitTest(point: CGPoint, flipped: Bool) -> Hotspot? {
        // Adjust point for flip if needed
        var testPoint = point

        if flipped {
            testPoint.x = spriteSize.width - point.x
        }

        // Find first hotspot containing the point
        for hotspot in hotspots {
            if hotspot.rect.contains(testPoint) {
                // Check condition if present
                if let condition = hotspot.condition {
                    if !evaluateCondition(condition) {
                        continue
                    }
                }
                return hotspot
            }
        }

        return nil
    }

    /// Test if a point in view coordinates hits any hotspot
    /// - Parameters:
    ///   - viewPoint: Point in view coordinate space (0,0 is top-left)
    ///   - viewSize: Size of the view
    ///   - flipped: Whether the sprite is horizontally flipped
    /// - Returns: The hotspot that was hit, or nil
    func hitTest(viewPoint: CGPoint, viewSize: CGSize, flipped: Bool) -> Hotspot? {
        // Convert from view coordinates (top-left origin) to sprite coordinates (bottom-left origin)
        let scaleX = spriteSize.width / viewSize.width
        let scaleY = spriteSize.height / viewSize.height

        let spritePoint = CGPoint(
            x: viewPoint.x * scaleX,
            y: (viewSize.height - viewPoint.y) * scaleY  // Flip Y axis
        )

        return hitTest(point: spritePoint, flipped: flipped)
    }

    // MARK: - Condition Evaluation

    /// Evaluate a condition expression
    /// Supports basic conditions like:
    /// - ${state == idle}
    /// - #{random < 0.5}
    private func evaluateCondition(_ condition: String) -> Bool {
        // For now, return true for all conditions
        // This can be extended to support Shimeji-ee style expressions

        // Check for state conditions
        if condition.contains("state") {
            // Would need access to current pet state
            return true
        }

        // Check for random conditions
        if condition.contains("random") {
            // Parse random threshold
            if let range = condition.range(of: #"random\s*<\s*([0-9.]+)"#, options: .regularExpression) {
                let match = String(condition[range])
                if let threshold = Double(match.components(separatedBy: "<").last?.trimmingCharacters(in: .whitespaces) ?? "") {
                    return Double.random(in: 0...1) < threshold
                }
            }
            return Double.random(in: 0...1) < 0.5
        }

        return true
    }

    // MARK: - Accessors

    /// Check if there are any hotspots
    var hasHotspots: Bool {
        !hotspots.isEmpty
    }

    /// Get all hotspots
    var allHotspots: [Hotspot] {
        hotspots
    }

    /// Get hotspots for a specific behavior
    func getHotspots(for behavior: String) -> [Hotspot] {
        hotspots.filter { $0.behavior == behavior }
    }
}

// MARK: - Hotspot Visualization (for debugging)

extension HotspotManager {
    /// Get hotspot rects for visualization
    func getHotspotRects(flipped: Bool) -> [(rect: CGRect, behavior: String)] {
        hotspots.map { hotspot in
            var rect = hotspot.rect

            if flipped {
                rect.origin.x = spriteSize.width - rect.maxX
            }

            return (rect, hotspot.behavior)
        }
    }
}

// MARK: - Default Hotspots

extension HotspotManager {
    /// Create default hotspots for common interactions
    static func createDefaultHotspots() -> [Hotspot] {
        return [
            // Head area - triggers happy
            Hotspot(
                rect: CGRect(x: 32, y: 88, width: 64, height: 40),
                behavior: "happy"
            ),
            // Body area - triggers curious
            Hotspot(
                rect: CGRect(x: 24, y: 40, width: 80, height: 48),
                behavior: "curious"
            )
        ]
    }
}
