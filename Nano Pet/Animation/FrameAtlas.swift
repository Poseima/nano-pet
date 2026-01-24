//
//  FrameAtlas.swift
//  Dream Pet
//
//  Frame atlas defining all 46 sprite frames and their metadata.
//

import Foundation
import CoreGraphics

// MARK: - Frame Category

/// Categories of animation frames
enum FrameCategory: String, CaseIterable {
    case standing   // 1
    case walking    // 2-3
    case falling    // 4
    case dragging   // 5-10
    case sitting    // 11, 15-17, 26-33
    case wall       // 12-14
    case ceiling    // 23-25
    case landing    // 18-19
    case lying      // 20-21
    case jumping    // 22
    case window     // 34-37
    case breeding   // 38-46
}

// MARK: - Frame Info

/// Information about a single frame
struct FrameInfo: Equatable {
    let category: FrameCategory
    let anchor: CGPoint
    let purpose: String

    /// Default sprite size
    static let defaultSize = CGSize(width: 128, height: 128)
}

// MARK: - Frame Atlas

/// Static atlas of all 46 frames with metadata
struct FrameAtlas {

    /// All frame definitions
    static let frames: [Int: FrameInfo] = [
        1:  FrameInfo(category: .standing, anchor: CGPoint(x: 64, y: 128), purpose: "idle"),
        2:  FrameInfo(category: .walking, anchor: CGPoint(x: 64, y: 128), purpose: "walk_left"),
        3:  FrameInfo(category: .walking, anchor: CGPoint(x: 64, y: 128), purpose: "walk_right"),
        4:  FrameInfo(category: .falling, anchor: CGPoint(x: 64, y: 128), purpose: "fall"),
        5:  FrameInfo(category: .dragging, anchor: CGPoint(x: 64, y: 128), purpose: "drag_tilt_left_1"),
        6:  FrameInfo(category: .dragging, anchor: CGPoint(x: 64, y: 128), purpose: "drag_tilt_right_1"),
        7:  FrameInfo(category: .dragging, anchor: CGPoint(x: 64, y: 128), purpose: "drag_tilt_left_2"),
        8:  FrameInfo(category: .dragging, anchor: CGPoint(x: 64, y: 128), purpose: "drag_tilt_right_2"),
        9:  FrameInfo(category: .dragging, anchor: CGPoint(x: 64, y: 128), purpose: "drag_tilt_left_3"),
        10: FrameInfo(category: .dragging, anchor: CGPoint(x: 64, y: 128), purpose: "drag_tilt_right_3"),
        11: FrameInfo(category: .sitting, anchor: CGPoint(x: 64, y: 128), purpose: "sit_default"),
        12: FrameInfo(category: .wall, anchor: CGPoint(x: 64, y: 128), purpose: "climb_mid"),
        13: FrameInfo(category: .wall, anchor: CGPoint(x: 64, y: 128), purpose: "climb_grip"),
        14: FrameInfo(category: .wall, anchor: CGPoint(x: 64, y: 128), purpose: "climb_reach"),
        15: FrameInfo(category: .sitting, anchor: CGPoint(x: 64, y: 128), purpose: "sit_turn_45"),
        16: FrameInfo(category: .sitting, anchor: CGPoint(x: 64, y: 128), purpose: "sit_turn_90"),
        17: FrameInfo(category: .sitting, anchor: CGPoint(x: 64, y: 128), purpose: "sit_turn_135"),
        18: FrameInfo(category: .landing, anchor: CGPoint(x: 64, y: 128), purpose: "bounce_1"),
        19: FrameInfo(category: .landing, anchor: CGPoint(x: 64, y: 128), purpose: "bounce_2"),
        20: FrameInfo(category: .lying, anchor: CGPoint(x: 64, y: 128), purpose: "sprawl_1"),
        21: FrameInfo(category: .lying, anchor: CGPoint(x: 64, y: 128), purpose: "sprawl_2"),
        22: FrameInfo(category: .jumping, anchor: CGPoint(x: 64, y: 128), purpose: "jump_air"),
        23: FrameInfo(category: .ceiling, anchor: CGPoint(x: 64, y: 48), purpose: "hang_grip"),
        24: FrameInfo(category: .ceiling, anchor: CGPoint(x: 64, y: 48), purpose: "hang_move_1"),
        25: FrameInfo(category: .ceiling, anchor: CGPoint(x: 64, y: 48), purpose: "hang_move_2"),
        26: FrameInfo(category: .sitting, anchor: CGPoint(x: 64, y: 128), purpose: "sit_look_up"),
        27: FrameInfo(category: .sitting, anchor: CGPoint(x: 64, y: 128), purpose: "head_spin_1"),
        28: FrameInfo(category: .sitting, anchor: CGPoint(x: 64, y: 128), purpose: "head_spin_2"),
        29: FrameInfo(category: .sitting, anchor: CGPoint(x: 64, y: 128), purpose: "sit_legs_variant"),
        30: FrameInfo(category: .sitting, anchor: CGPoint(x: 64, y: 112), purpose: "sit_legs_up"),
        31: FrameInfo(category: .sitting, anchor: CGPoint(x: 64, y: 112), purpose: "sit_legs_down"),
        32: FrameInfo(category: .sitting, anchor: CGPoint(x: 64, y: 112), purpose: "sit_dangle_left"),
        33: FrameInfo(category: .sitting, anchor: CGPoint(x: 64, y: 112), purpose: "sit_dangle_right"),
        34: FrameInfo(category: .window, anchor: CGPoint(x: 64, y: 128), purpose: "window_hold_1"),
        35: FrameInfo(category: .window, anchor: CGPoint(x: 64, y: 128), purpose: "window_hold_2"),
        36: FrameInfo(category: .window, anchor: CGPoint(x: 64, y: 128), purpose: "window_hold_fall"),
        37: FrameInfo(category: .window, anchor: CGPoint(x: 64, y: 128), purpose: "window_throw"),
        38: FrameInfo(category: .breeding, anchor: CGPoint(x: 96, y: 128), purpose: "pullup_reach"),
        39: FrameInfo(category: .breeding, anchor: CGPoint(x: 96, y: 128), purpose: "pullup_grab"),
        40: FrameInfo(category: .breeding, anchor: CGPoint(x: 96, y: 128), purpose: "pullup_lift"),
        41: FrameInfo(category: .breeding, anchor: CGPoint(x: 96, y: 128), purpose: "pullup_done"),
        42: FrameInfo(category: .breeding, anchor: CGPoint(x: 64, y: 128), purpose: "divide_1"),
        43: FrameInfo(category: .breeding, anchor: CGPoint(x: 64, y: 128), purpose: "divide_2"),
        44: FrameInfo(category: .breeding, anchor: CGPoint(x: 64, y: 128), purpose: "divide_3"),
        45: FrameInfo(category: .breeding, anchor: CGPoint(x: 64, y: 128), purpose: "divide_4"),
        46: FrameInfo(category: .breeding, anchor: CGPoint(x: 64, y: 128), purpose: "divide_done"),
    ]

    /// Get frame info for a given frame number
    static func info(for frame: Int) -> FrameInfo? {
        frames[frame]
    }

    /// Get all frames for a category
    static func frames(for category: FrameCategory) -> [Int] {
        frames.filter { $0.value.category == category }.map { $0.key }.sorted()
    }

    /// Total frame count
    static let totalFrames = 46
}
