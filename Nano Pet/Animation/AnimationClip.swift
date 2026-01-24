//
//  AnimationClip.swift
//  Dream Pet
//
//  Animation clip data structure for frame sequences.
//

import Foundation

// MARK: - Animation Clip

/// A sequence of frames that form an animation
struct AnimationClip {
    /// Name of the clip
    let name: String

    /// Frame numbers in the sequence
    let frames: [Int]

    /// Duration of each frame in ticks (60 ticks = 1 second at 60fps)
    let frameDuration: Int

    /// Whether the animation loops
    let loop: Bool

    /// Total duration in ticks
    var totalDuration: Int {
        frames.count * frameDuration
    }

    /// Get frame at a specific tick
    func frame(at tick: Int) -> Int {
        let frameIndex: Int
        if loop {
            frameIndex = (tick / frameDuration) % frames.count
        } else {
            frameIndex = min(tick / frameDuration, frames.count - 1)
        }
        return frames[frameIndex]
    }

    /// Check if animation is complete at tick
    func isComplete(at tick: Int) -> Bool {
        !loop && tick >= totalDuration
    }
}

// MARK: - Frame Selection

/// Result of frame selection
struct FrameSelection: Equatable {
    let number: Int
    let flipped: Bool
}
