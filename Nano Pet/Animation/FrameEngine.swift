//
//  FrameEngine.swift
//  Dream Pet
//
//  Handles frame sequencing and selection for animations.
//

import Foundation
import CoreGraphics

// MARK: - Frame Engine

/// Engine for selecting animation frames
final class FrameEngine {

    // MARK: - Predefined Animation Clips

    static let clips: [String: AnimationClip] = [
        "idle":         AnimationClip(name: "idle", frames: [1], frameDuration: 120, loop: true),
        "walk":         AnimationClip(name: "walk", frames: [1, 2, 1, 3], frameDuration: 36, loop: true),
        "fall":         AnimationClip(name: "fall", frames: [4], frameDuration: 1, loop: true),
        "land":         AnimationClip(name: "land", frames: [18, 19, 1], frameDuration: 8, loop: false),
        "jump":         AnimationClip(name: "jump", frames: [22], frameDuration: 1, loop: true),
        "sit":          AnimationClip(name: "sit", frames: [11], frameDuration: 120, loop: true),
        "sit_look":     AnimationClip(name: "sit_look", frames: [11, 15, 16, 17, 16, 15, 11], frameDuration: 24, loop: true),
        "sit_spin":     AnimationClip(name: "sit_spin", frames: [27, 28, 27, 28], frameDuration: 24, loop: false),
        "lie":          AnimationClip(name: "lie", frames: [20, 21], frameDuration: 60, loop: true),
        "climb":        AnimationClip(name: "climb", frames: [14, 12, 13, 13, 12, 14], frameDuration: 24, loop: true),
        "ceiling":      AnimationClip(name: "ceiling", frames: [25, 23, 24, 24, 23, 25], frameDuration: 24, loop: true),
        "ceiling_hang": AnimationClip(name: "ceiling_hang", frames: [23], frameDuration: 120, loop: true),
        "dangle":       AnimationClip(name: "dangle", frames: [30, 31, 32, 33, 32, 31], frameDuration: 48, loop: true),
        // Division: buildup pulse (42-43), stretch (44-45), split (46), settle back
        "divide":       AnimationClip(name: "divide", frames: [42, 43, 42, 43, 44, 45, 44, 45, 46, 46, 46, 45, 44, 43, 42], frameDuration: 12, loop: false),
        "thrown":       AnimationClip(name: "thrown", frames: [37], frameDuration: 1, loop: true),
        "sit_lookup":   AnimationClip(name: "sit_lookup", frames: [11, 26, 26, 11], frameDuration: 75, loop: true),
        "sit_stretch":  AnimationClip(name: "sit_stretch", frames: [11, 29, 29, 11], frameDuration: 75, loop: true),
        "window_walk":  AnimationClip(name: "window_walk", frames: [1, 2, 1, 3], frameDuration: 36, loop: true),
        "window_hold":  AnimationClip(name: "window_hold", frames: [34, 35, 36], frameDuration: 24, loop: true),
        "window_fall":  AnimationClip(name: "window_fall", frames: [36], frameDuration: 1, loop: true),
        "pullup":       AnimationClip(name: "pullup", frames: [38, 39, 40, 41], frameDuration: 30, loop: false),

        // Teleport animations (using existing frames as placeholders - fade effect handled in view)
        "teleport_out": AnimationClip(name: "teleport_out", frames: [1], frameDuration: 12, loop: false),
        "teleport_in":  AnimationClip(name: "teleport_in", frames: [1], frameDuration: 12, loop: false),

        // Pose showing: sit → look up → turn → arms up → cheer → return
        "pose_show":    AnimationClip(name: "pose_show", frames: [11, 26, 27, 28, 29, 28, 27, 26, 11], frameDuration: 45, loop: true),
    ]

    // MARK: - State

    private var currentClipName: String?
    private var clipStartTick: UInt64 = 0
    private var direction: Direction = .left

    // MARK: - Public API

    /// Play a specific animation clip
    /// - Parameters:
    ///   - name: Name of the clip to play
    ///   - direction: Direction for flipping (right = flipped)
    ///   - tick: Current tick for timing (optional, used when called from hint)
    func playClip(_ name: String, direction: Direction = .left, tick: UInt64 = 0) {
        if currentClipName != name {
            currentClipName = name
            clipStartTick = tick // Set to current tick for proper timing
            self.direction = direction
        }
    }

    /// Update direction without resetting animation
    func setDirection(_ dir: Direction) {
        self.direction = dir
    }

    /// Reset clip tracking for fresh animation start
    func resetClipTracking() {
        print("[FrameEngine] resetClipTracking() called, was clip=\(currentClipName ?? "nil") start=\(clipStartTick)")
        currentClipName = nil
        clipStartTick = 0
    }

    /// Select the appropriate frame based on state and motion
    /// - Parameters:
    ///   - state: Current pet state
    ///   - motion: Motion result from physics
    ///   - tick: Current tick count
    /// - Returns: Frame selection with number and flip state
    func selectFrame(state: PetState, motion: MotionResult, tick: UInt64) -> FrameSelection {
        // Map state to clip
        let clipName = mapStateToClip(state: state, motion: motion)

        if currentClipName != clipName {
            currentClipName = clipName
            clipStartTick = tick
        }

        guard let clip = Self.clips[clipName] ?? Self.clips["idle"] else {
            return FrameSelection(number: 1, flipped: false)
        }

        // Calculate frame index
        let ticksElapsed = Int(tick - clipStartTick)
        let frameNumber = clip.frame(at: ticksElapsed)

        // Determine flip based on direction
        let flipped = direction == .right

        return FrameSelection(number: frameNumber, flipped: flipped)
    }

    /// Select frame with explicit hint
    /// - Parameters:
    ///   - hint: Frame hint from state decision
    ///   - tick: Current tick count
    /// - Returns: Frame selection
    func selectFrame(hint: FrameHint, tick: UInt64) -> FrameSelection {
        switch hint {
        case .frame(let num):
            currentClipName = nil  // Clear so next clip starts fresh
            return FrameSelection(number: num, flipped: direction == .right)

        case .clip(let name, let dir):
            direction = dir
            let wasClipName = currentClipName
            let wasClipStartTick = clipStartTick
            playClip(name, direction: dir, tick: tick)
            guard let clip = Self.clips[name] else {
                print("[FrameEngine] ERROR: clip '\(name)' not found!")
                return FrameSelection(number: 1, flipped: false)
            }
            let ticksElapsed = Int(tick - clipStartTick)
            let frame = clip.frame(at: ticksElapsed)
            return FrameSelection(number: frame, flipped: dir == .right)

        case .dragTilt(let offset):
            let frame = selectDragFrame(cursorOffset: offset)
            return FrameSelection(number: frame, flipped: false)
        }
    }

    /// Special handling for dragged state - frame based on tilt
    func selectDragFrame(cursorOffset: CGFloat) -> Int {
        switch cursorOffset {
        case ..<(-40): return 9
        case -40..<(-20): return 7
        case -20..<0: return 5
        case 0..<20: return 6
        case 20..<40: return 8
        default: return 10
        }
    }

    /// Check if current clip is complete (for non-looping clips)
    func isClipComplete(tick: UInt64) -> Bool {
        guard let clipName = currentClipName,
              let clip = Self.clips[clipName] else {
            return true
        }
        let ticksElapsed = Int(tick - clipStartTick)
        return clip.isComplete(at: ticksElapsed)
    }

    // MARK: - Private Helpers

    private func mapStateToClip(state: PetState, motion: MotionResult) -> String {
        switch state.name {
        case "idle": return "idle"
        case "walking": return "walk"
        case "falling": return "fall"
        case "jumping": return "jump"
        case "landing": return "land"
        case "sitting": return "sit"
        case "lying": return "lie"
        case "climbing": return "climb"
        case "ceiling": return "ceiling"
        case "dangling": return "dangle"
        case "dividing": return "divide"
        case "thrown": return "thrown"
        case "lookAround": return "sit_look"
        case "sitLookUp": return "sit_lookup"
        case "sitStretch": return "sit_stretch"
        case "windowWalking": return "window_walk"
        case "windowHolding": return "window_hold"
        case "windowFalling": return "window_fall"
        case "pullup": return "pullup"
        case "teleport_out": return "teleport_out"
        case "teleport_in": return "teleport_in"
        case "poseShowing": return "pose_show"
        default: return "idle"
        }
    }
}
