//
//  PetViewModel.swift
//  Nano Pet
//
//  View model for pet instances.
//  Integrates with PetBrain for behavior orchestration.
//

import SwiftUI
import Combine
#if os(macOS)
import AppKit
#endif

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Pet ViewModel

@Observable
class PetViewModel {

    // MARK: - Brain Controller

    /// The brain controller that handles all behavior
    private var brainController: PetBrainViewController?

    // MARK: - View Properties

    /// Current frame number (1-46)
    private(set) var currentFrame: Int = 1

    /// Whether sprite should be flipped horizontally
    private(set) var flipHorizontal: Bool = false

    /// Current position
    private(set) var position: CGPoint = .zero

    /// Current behavior name
    private(set) var behaviorName: String = "Idle"

    /// Current state name (for animations like teleport)
    private(set) var currentStateName: String = "idle"

    /// Teleport progress (0.0 to 1.0) - used for fade animation
    private(set) var teleportProgress: Double = 0.0

    // MARK: - Window Management

    var windowFrame: CGRect = .zero
    var onWindowMoveRequest: ((CGPoint) -> Void)?

    // MARK: - Pet Name

    private(set) var petName: String = ""

    // MARK: - Spawn Callback

    /// Called when the brain requests spawning a child pet
    var onSpawnChild: (() -> Void)?

    // MARK: - Initialization

    init() {}

    init(petName: String) {
        initializeMascot(petName: petName)
    }

    deinit {
        brainController?.stop()
    }

    // MARK: - Mascot Initialization

    func initializeMascot(petName: String) {
        print("[PetViewModel] initializeMascot(\(petName))")
        self.petName = petName

        #if os(macOS)
        // Set initial position
        if let screen = NSScreen.main {
            let visibleFrame = screen.visibleFrame
            position = CGPoint(x: visibleFrame.midX - 64, y: visibleFrame.minY)
            print("[PetViewModel] Initial position: \(position)")
        }

        // Create and configure brain controller
        brainController = PetBrainViewController(petName: petName)

        // Connect callbacks
        brainController?.onFrameChanged = { [weak self] (frame: Int, flipped: Bool) in
            self?.currentFrame = frame
            self?.flipHorizontal = flipped
        }

        // State change callback - called every tick for teleport fade effect
        brainController?.onStateChanged = { [weak self] (stateName: String) in
            guard let self = self else { return }

            // Track state name change
            let previousStateName = self.currentStateName
            self.currentStateName = stateName
            self.behaviorName = stateName.capitalized

            // Reset progress on state change
            if previousStateName != stateName {
                self.teleportProgress = 0.0
            }

            // Increment progress during teleport states
            if stateName == "teleport_out" || stateName == "teleport_in" {
                self.teleportProgress = min(1.0, self.teleportProgress + (1.0 / 30.0))
            }
        }

        brainController?.onPositionChanged = { [weak self] (newPosition: CGPoint) in
            guard let self = self else { return }
            self.position = newPosition
            // Offset window origin to account for sprite anchor
            let windowOrigin = CGPoint(x: newPosition.x, y: newPosition.y)
            self.onWindowMoveRequest?(windowOrigin)
        }

        brainController?.onSpawnChild = { [weak self] in
            self?.onSpawnChild?()
        }

        brainController?.onPlaySound = { (soundName: String) in
            SoundManager.shared.play(soundName)
        }

        // Set initial position and start
        brainController?.setInitialPosition(position)
        brainController?.start()

        // Update behavior name binding
        behaviorName = brainController?.stateName ?? "Idle"
        #endif
    }

    // MARK: - Window Frame

    func updateWindowFrame(_ frame: CGRect) {
        self.windowFrame = frame
    }

    // MARK: - User Interaction

    func onTap() {
        print("[PetViewModel] Tap at \(position)")
        brainController?.handleTap()

        // Trigger a random reaction to tap
        if Bool.random() && !AppSettings.shared.disableJumping {
            brainController?.triggerJump()
        }
    }

    func onDragStart() {
        print("[PetViewModel] Drag started")
        brainController?.handleDragStart()
    }

    func onDragMove(to point: CGPoint) {
        // Position is now handled by the brain through cursor tracking
        // The brain's SenseEngine reads cursor position directly
    }

    func onDragEnd() {
        print("[PetViewModel] Drag ended")
        brainController?.handleDragEnd()
    }

    func triggerRandomBehavior() {
        brainController?.triggerRandomBehavior()
    }

    func triggerDivideBehavior() {
        brainController?.triggerDivide()
    }

    /// Trigger a specific state
    func triggerState(_ state: any PetState) {
        brainController?.triggerState(state)
    }

    /// Start a specific routine
    func startRoutine(_ routine: any Routine) {
        brainController?.startRoutine(routine)
    }

    /// Set the pet's position directly (used for focus mode)
    func setPosition(_ newPosition: CGPoint) {
        position = newPosition
        brainController?.setInitialPosition(newPosition)
        onWindowMoveRequest?(newPosition)
    }

    /// 设置完整的宠物身份标识（包含编号，用于日志记录）
    func setPetIdentifier(_ identifier: String) {
        brainController?.updatePetIdentifier(identifier)
    }

    // MARK: - Screen Bounds Updates

    #if os(macOS)
    func updateScreenBounds(from screen: NSScreen) {
        // Screen bounds are handled by the brain's SenseEngine
        // which queries WindowDetector.shared.screenBounds
    }
    #endif

    // MARK: - Testing Support

    /// Run quick verification of the brain system
    func runQuickVerify() -> Bool {
        brainController?.runQuickVerify() ?? false
    }

    /// Run all tests
    func runAllTests() -> [TestResult] {
        brainController?.runAllTests() ?? []
    }
}
