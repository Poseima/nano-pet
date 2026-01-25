//
//  PhysicsEngine.swift
//  Dream Pet
//
//  Handles all physical movement with deterministic simulation.
//

import Foundation
import CoreGraphics
#if os(macOS)
import AppKit
#endif

// MARK: - Motion Intent

/// Intended motion from state decisions
enum MotionIntent: Equatable {
    case stay
    case walk(direction: Direction, speed: Speed)
    case jump(power: CGFloat)
    case fall
    case climb(direction: Direction)
    case ceilingWalk(direction: Direction)
    case followCursor
    case throwWithVelocity(CGVector)
    case teleportTo(CGPoint)  // Instant position change
}

// MARK: - Physics Engine

/// Engine for physical movement simulation
final class PhysicsEngine {

    // MARK: - Configuration

    var config = PhysicsConfig.default

    // MARK: - State

    private(set) var velocity: CGVector = .zero
    private var acceleration: CGVector = .zero

    /// Pet size for collision detection
    var petSize: CGSize = CGSize(width: 128, height: 128)

    // MARK: - Apply Motion

    /// Apply motion intent and return new position
    /// - Parameters:
    ///   - decision: The state decision with motion intent
    ///   - currentPosition: Current position
    ///   - perception: Current environment perception
    /// - Returns: Motion result with new position and collisions
    func apply(decision: StateDecision, currentPosition: CGPoint, perception: Perception) -> MotionResult {
        var pos = currentPosition
        var collisions: [Collision] = []
        var surface: SurfaceType? = nil

        switch decision.motionIntent {
        case .stay:
            velocity = .zero

        case .walk(let dir, let speed):
            let spd = speed == .run ? config.runSpeed : (speed == .slow ? config.walkSpeed * 0.5 : config.walkSpeed)
            velocity.dx = dir == .left ? -spd : spd
            velocity.dy = 0

        case .jump(let power):
            velocity.dy = power

        case .fall:
            // Apply gravity
            velocity.dy -= config.gravity
            velocity.dy = max(velocity.dy, -config.terminalVelocity)
            // Apply air resistance
            velocity.dx *= (1 - config.airResistance)

        case .climb(let dir):
            velocity.dx = 0
            switch dir {
            case .up:
                velocity.dy = config.climbSpeed
            case .down:
                velocity.dy = -config.climbSpeed
            case .left, .right:
                // Horizontal directions shouldn't be used for climb, but default to up
                velocity.dy = config.climbSpeed
            }

        case .ceilingWalk(let dir):
            velocity.dx = dir == .left ? -config.climbSpeed : config.climbSpeed
            velocity.dy = 0

        case .followCursor:
            pos = perception.cursorPosition
            // Offset to center the pet on cursor
            pos.x -= petSize.width / 2
            pos.y -= petSize.height / 2

            // 专注模式下，将位置限制在主屏幕边界内
            #if os(macOS)
            if AppSettings.shared.behaviorMode == .focus {
                // 使用主显示器边界（NSScreen.screens.first），而不是当前屏幕
                if let primaryScreen = NSScreen.screens.first {
                    let screenBounds = primaryScreen.visibleFrame
                    pos.x = max(screenBounds.minX, min(pos.x, screenBounds.maxX - petSize.width))
                    pos.y = max(screenBounds.minY, min(pos.y, screenBounds.maxY - petSize.height))
                }
            }
            #endif

            velocity = .zero
            return MotionResult(newPosition: pos, velocity: velocity, collisions: [], surfaceType: nil)

        case .throwWithVelocity(let v):
            velocity = CGVector(dx: v.dx * config.throwMultiplier, dy: v.dy * config.throwMultiplier)

        case .teleportTo(let targetPos):
            // Clamp teleport destination to valid screen bounds
            var validPos = targetPos
            validPos.x = max(0, min(validPos.x, perception.bounds.rightX - petSize.width))
            validPos.y = max(perception.bounds.floorY, min(validPos.y, perception.bounds.ceilingY - petSize.height))
            pos = validPos
            velocity = .zero
            return MotionResult(newPosition: pos, velocity: velocity, collisions: [], surfaceType: nil)
        }

        // Integrate position
        pos.x += velocity.dx
        pos.y += velocity.dy

        // Collision detection with bounds
        let bounds = perception.bounds

        // Floor collision
        if pos.y <= bounds.floorY {
            pos.y = bounds.floorY
            if velocity.dy < -config.minBounceVelocity {
                velocity.dy = -velocity.dy * config.bounceDecay
                collisions.append(Collision(edge: .down, point: pos, normal: CGVector(dx: 0, dy: 1)))
            } else {
                velocity.dy = 0
            }
            surface = .floor
        }

        // Left wall handling
        if pos.x <= bounds.leftX {
            if perception.isInAir {
                // Airborne - allow screen wrap when fully off screen
                if pos.x < bounds.leftX - petSize.width {
                    pos.x = bounds.rightX
                }
            } else {
                // On ground - wall collision for climbing
                // 负偏移让窗口超出边界，补偿精灵图的透明边距
                let spriteOffset = petSize.width * ScreenScaling.spriteOffsetRatio
                pos.x = max(0, bounds.leftX - spriteOffset)
                velocity.dx = 0
                collisions.append(Collision(edge: .left, point: pos, normal: CGVector(dx: 1, dy: 0)))
                surface = .wall(.left)
            }
        }

        // Right wall handling
        if pos.x >= bounds.rightX - petSize.width {
            if perception.isInAir {
                // Airborne - allow screen wrap when fully off screen
                if pos.x > bounds.rightX {
                    pos.x = bounds.leftX - petSize.width
                }
            } else {
                // On ground - wall collision for climbing
                // 正偏移让窗口超出边界，补偿精灵图的透明边距
                let spriteOffset = petSize.width * ScreenScaling.spriteOffsetRatio
                pos.x = bounds.rightX - petSize.width + spriteOffset
                velocity.dx = 0
                collisions.append(Collision(edge: .right, point: pos, normal: CGVector(dx: -1, dy: 0)))
                surface = .wall(.right)
            }
        }

        // Ceiling collision - only apply when moving upward or already at ceiling
        if pos.y >= bounds.ceilingY - petSize.height {
            if velocity.dy > config.minBounceVelocity {
                // Bouncing off ceiling
                velocity.dy = -velocity.dy * config.bounceDecay
                pos.y = bounds.ceilingY - petSize.height - 1
                collisions.append(Collision(edge: .up, point: pos, normal: CGVector(dx: 0, dy: -1)))
                surface = .ceiling
            } else if velocity.dy > 0 {
                // Moving upward slowly - stop at ceiling with visual offset
                let spriteOffset = petSize.height * ScreenScaling.spriteOffsetRatio
                pos.y = bounds.ceilingY - petSize.height + spriteOffset
                velocity.dy = 0
                collisions.append(Collision(edge: .up, point: pos, normal: CGVector(dx: 0, dy: -1)))
                surface = .ceiling
            }
            // If velocity.dy <= 0, don't apply ceiling offset - pet is just near ceiling, not hitting it
        }

        // Window surface detection
        if let window = perception.windowBelow {
            if abs(pos.y - window.topY) < 5 {
                pos.y = window.topY
                if velocity.dy < 0 {
                    collisions.append(Collision(edge: .down, point: pos, normal: CGVector(dx: 0, dy: 1)))
                }
                velocity.dy = 0
                surface = .windowTop
            }
        }

        return MotionResult(newPosition: pos, velocity: velocity, collisions: collisions, surfaceType: surface)
    }

    // MARK: - State Management

    /// Reset velocity and acceleration
    func reset() {
        velocity = .zero
        acceleration = .zero
    }

    /// Set velocity directly
    func setVelocity(_ v: CGVector) {
        velocity = v
    }

    /// Get current speed
    var speed: CGFloat {
        hypot(velocity.dx, velocity.dy)
    }

    /// Check if moving
    var isMoving: Bool {
        speed > 0.1
    }

    /// Get movement direction
    var movementDirection: Direction? {
        if abs(velocity.dx) > abs(velocity.dy) {
            return velocity.dx < 0 ? .left : .right
        } else if abs(velocity.dy) > 0.1 {
            return velocity.dy > 0 ? .up : .down
        }
        return nil
    }
}
