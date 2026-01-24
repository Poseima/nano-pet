//
//  PetBrainViewController.swift
//  Dream Pet
//
//  Connects the PetBrain orchestrator to the existing UI system.
//

import Foundation
import CoreGraphics
#if os(macOS)
import AppKit
import QuartzCore
#endif

// MARK: - Pet Brain View Controller

/// Controller that bridges PetBrain to the window system
final class PetBrainViewController {

    // MARK: - Properties

    /// The brain orchestrator
    let brain: PetBrain

    /// Pet name (for sprite loading)
    let petName: String

    /// Display link for 60fps updates
    #if os(macOS)
    private var displayLink: CVDisplayLink?
    #endif

    /// Whether the controller is running
    private(set) var isRunning: Bool = false

    // MARK: - Callbacks

    /// Called when frame changes (for view updates)
    var onFrameChanged: ((Int, Bool) -> Void)?

    /// Called when position changes (for window movement)
    var onPositionChanged: ((CGPoint) -> Void)?

    /// Called when state changes (for teleport fade effects)
    var onStateChanged: ((String) -> Void)?

    /// Called to spawn a child pet
    var onSpawnChild: (() -> Void)?

    /// Called to play a sound
    var onPlaySound: ((String) -> Void)?

    // MARK: - Initialization

    init(petName: String) {
        self.petName = petName
        self.brain = PetBrain()
        // 初始时使用 petName，后续可通过 updatePetIdentifier 更新为完整 displayName
        self.brain.petIdentifier = petName

        setupBrain()
    }

    /// 更新宠物身份标识（用于日志记录）
    func updatePetIdentifier(_ identifier: String) {
        brain.petIdentifier = identifier
    }

    private func setupBrain() {
        // Connect SenseEngine to WindowDetector
        brain.senseEngine.screenBoundsProvider = { [weak self] () -> CGRect in
            // 专注模式下使用主显示器边界，防止宠物移动到扩展屏幕
            if AppSettings.shared.behaviorMode == .focus {
                return WindowDetector.shared.primaryScreenBounds
            }
            // 使用宠物当前所在屏幕的边界，而不是 NSScreen.main
            // 这修复了扩展屏幕上的闪烁问题
            guard let position = self?.brain.position else {
                return WindowDetector.shared.screenBounds
            }
            return WindowDetector.shared.screenBoundsForPoint(position)
        }

        brain.senseEngine.windowsProvider = { () -> [WindowInfo] in
            return WindowDetector.shared.windows.map { (window: DetectedWindow) -> WindowInfo in
                WindowInfo(
                    id: window.id,
                    frame: window.frame,
                    topY: window.topEdge,
                    name: window.ownerName
                )
            }
        }

        // Connect velocity from physics engine for jump arc detection
        brain.senseEngine.velocityProvider = { [weak self] () -> CGVector in
            return self?.brain.physicsEngine.velocity ?? .zero
        }

        // Connect active window provider for teleport system
        brain.senseEngine.activeWindowProvider = { () -> (name: String, window: WindowInfo?, didChange: Bool) in
            let detector = WindowDetector.shared
            let activeWindow: WindowInfo?
            if let detectedWindow = detector.activeWindow {
                activeWindow = WindowInfo(
                    id: detectedWindow.id,
                    frame: detectedWindow.frame,
                    topY: detectedWindow.topEdge,
                    name: detectedWindow.ownerName
                )
            } else {
                activeWindow = nil
            }
            return (
                name: detector.activeAppName,
                window: activeWindow,
                didChange: detector.activeAppDidChange
            )
        }

        // Connect callbacks
        brain.onPositionChanged = { [weak self] (position: CGPoint) in
            self?.onPositionChanged?(position)
        }

        brain.onSpawnChild = { [weak self] in
            self?.onSpawnChild?()
        }

        brain.onPlaySound = { [weak self] (sound: String) in
            self?.onPlaySound?(sound)
        }
    }

    // MARK: - Lifecycle

    /// Start the update loop
    func start() {
        guard !isRunning else { return }
        isRunning = true

        #if os(macOS)
        setupDisplayLink()
        #endif
    }

    /// Stop the update loop
    func stop() {
        guard isRunning else { return }
        isRunning = false

        #if os(macOS)
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
        displayLink = nil
        #endif
    }

    // MARK: - Display Link

    #if os(macOS)
    private func setupDisplayLink() {
        // 停止旧的 displayLink
        if let existing = displayLink {
            CVDisplayLinkStop(existing)
            displayLink = nil
        }

        var link: CVDisplayLink?
        // 使用 CVDisplayLinkCreateWithActiveCGDisplays 支持所有显示器
        // 这样宠物可以在不同屏幕间自由移动，不需要重建 DisplayLink
        CVDisplayLinkCreateWithActiveCGDisplays(&link)

        guard let displayLink = link else { return }

        self.displayLink = displayLink

        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, userInfo in
            guard let userInfo = userInfo else { return kCVReturnSuccess }
            let controller = Unmanaged<PetBrainViewController>.fromOpaque(userInfo).takeUnretainedValue()
            DispatchQueue.main.async {
                controller.tick()
            }
            return kCVReturnSuccess
        }

        CVDisplayLinkSetOutputCallback(displayLink, callback, Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkStart(displayLink)
    }
    #endif

    // MARK: - Update

    /// Process one tick
    private func tick() {
        guard isRunning else { return }

        let previousFrame = brain.currentFrame
        let previousFlip = brain.flipHorizontal

        brain.tick()

        // Always notify state changes (needed for teleport fade effect)
        onStateChanged?(brain.stateName)

        // Acknowledge active app change after processing to prevent repeated triggers
        WindowDetector.shared.acknowledgeActiveAppChange()

        // Notify if frame changed
        if brain.currentFrame != previousFrame || brain.flipHorizontal != previousFlip {
            onFrameChanged?(brain.currentFrame, brain.flipHorizontal)
        }
    }

    // MARK: - Input Handling

    /// Handle drag start
    func handleDragStart() {
        brain.startDrag()
    }

    /// Handle drag end
    func handleDragEnd() {
        brain.endDrag()
    }

    /// Handle tap
    func handleTap() {
        brain.registerTap()
    }

    // MARK: - Position

    /// Set initial position
    func setInitialPosition(_ position: CGPoint) {
        brain.setPosition(position)
    }

    /// Get current position
    var position: CGPoint {
        brain.position
    }

    // MARK: - State

    /// Current frame number
    var currentFrame: Int {
        brain.currentFrame
    }

    /// Current flip state
    var flipHorizontal: Bool {
        brain.flipHorizontal
    }

    /// Current state name
    var stateName: String {
        brain.stateName
    }

    // MARK: - Actions

    /// Trigger divide behavior
    func triggerDivide() {
        brain.triggerDivide()
    }

    /// Trigger jump
    func triggerJump() {
        brain.triggerJump()
    }

    /// Trigger random behavior
    func triggerRandomBehavior() {
        // Force a new behavior
        let states: [any PetState] = [
            WalkingState(direction: .randomHorizontal),
            SittingState(),
            JumpingState(),
            LookAroundState(),
            LyingState()
        ]
        if let state = states.randomElement() {
            brain.forceState(state)
        }
    }

    /// Trigger a specific state
    func triggerState(_ state: any PetState) {
        brain.forceState(state)
    }

    /// Start a specific routine
    func startRoutine(_ routine: any Routine) {
        brain.startRoutine(routine)
    }

    // MARK: - Testing

    /// Run quick verification
    func runQuickVerify() -> Bool {
        TestRunner.shared.quickVerify()
    }

    /// Run all tests
    func runAllTests() -> [TestResult] {
        TestRunner.shared.runAllTests()
    }

    // MARK: - Cleanup

    deinit {
        stop()
    }
}
