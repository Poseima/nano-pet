//
//  PetWindowController.swift
//  Nano Pet
//
//  桌面宠物的透明窗口控制器
//

import AppKit
import SwiftUI

class PetWindowController: NSWindowController {
    private var petViewModel: PetViewModel!
    private var dragStartOrigin: NSPoint = .zero
    private var isDragging: Bool = false
    private(set) var petName: String = ""  // 此宠物使用的角色名
    private var visibilityObserver: NSObjectProtocol?
    /// 当前窗口所在的屏幕（用于检测屏幕变化）
    private var currentScreen: NSScreen?

    /// Reference to the associated PetInstance (set by PetManager)
    weak var petInstance: PetInstance?

    /// 设置宠物身份标识（用于日志记录）
    func setPetIdentifier(_ identifier: String) {
        petViewModel.setPetIdentifier(identifier)
    }

    init(petName: String) {
        self.petName = petName

        // 创建透明无边框窗口
        let window = PetWindow(
            contentRect: NSRect(x: 0, y: 0, width: 128, height: 128),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // 配置窗口属性
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isMovableByWindowBackground = false
        window.acceptsMouseMovedEvents = true

        super.init(window: window)

        // 设置初始位置（屏幕中央偏下）
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 64
            let y = screenFrame.minY + 100
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // 创建 ViewModel 和视图 - initialize with petName to create mascot
        petViewModel = PetViewModel(petName: petName)

        // 设置窗口移动回调
        petViewModel.onWindowMoveRequest = { [weak self] newOrigin in
            self?.window?.setFrameOrigin(newOrigin)
            self?.updateViewModelWindowFrame()
        }

        // 创建 SpritePetView（使用指定的角色）
        // Use DraggableHostingView for reliable mouse event handling on borderless windows
        let petView = SpritePetView(petName: petName, viewModel: petViewModel)
        let hostingView = DraggableHostingView(rootView: petView)
        hostingView.dragDelegate = self
        hostingView.contextMenuDelegate = self
        window.contentView = hostingView

        // Connect spawn callback from brain
        petViewModel.onSpawnChild = { [weak self] in
            self?.spawnAnotherRequested()
        }

        // 设置窗口委托
        window.delegate = self

        // 初始化窗口位置信息
        updateViewModelWindowFrame()

        // 初始化当前屏幕
        currentScreen = window.screen

        // 记录初始位置用于拖拽
        dragStartOrigin = window.frame.origin

        // Register with WindowDetector to start window detection
        WindowDetector.shared.register()

        // 监听全屏状态变化，自动隐藏/显示宠物
        visibilityObserver = NotificationCenter.default.addObserver(
            forName: .petVisibilityChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let shouldHide = notification.userInfo?["hidden"] as? Bool else { return }
            self?.handleVisibilityChange(hidden: shouldHide)
        }
    }

    deinit {
        if let observer = visibilityObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        // Unregister from WindowDetector when pet is removed
        WindowDetector.shared.unregister()
    }

    /// 处理全屏隐藏/显示
    private func handleVisibilityChange(hidden: Bool) {
        if hidden {
            window?.orderOut(nil)
        } else {
            window?.orderFront(nil)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// 重新加载宠物视图
    private func reloadPetView() {
        guard let window = window else { return }

        // 保存当前位置
        let currentOrigin = window.frame.origin

        // 重新创建视图（使用此宠物的角色）
        let petView = SpritePetView(petName: petName, viewModel: petViewModel)
        let hostingView = DraggableHostingView(rootView: petView)
        hostingView.dragDelegate = self
        hostingView.contextMenuDelegate = self
        window.contentView = hostingView

        // 恢复位置
        window.setFrameOrigin(currentOrigin)
    }

    private func updateViewModelWindowFrame() {
        guard let window = window else { return }

        // 只追踪当前屏幕，不触发 DisplayLink 重建
        // CVDisplayLink 使用 CVDisplayLinkCreateWithActiveCGDisplays 已支持所有屏幕
        if let newScreen = window.screen, newScreen != currentScreen {
            currentScreen = newScreen
        }

        petViewModel.updateWindowFrame(window.frame)
    }

    // MARK: - Drag Handling

    private func handleDrag(translation: CGSize) {
        // Mascot system handles drag via DraggedAction
        // Window position is updated via mascot.anchor.didSet -> onWindowMoveRequest
        if !isDragging {
            isDragging = true
        }
    }

    private func handleDragEnd() {
        isDragging = false
    }

    // 触发随机行为
    func triggerRandomAction() {
        petViewModel.triggerRandomBehavior()
    }

    /// 设置宠物位置（用于专注模式移动到底部）
    func setPosition(_ position: CGPoint) {
        petViewModel.setPosition(position)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.orderFront(nil)
    }
}

// MARK: - NSWindowDelegate
extension PetWindowController: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        updateViewModelWindowFrame()
    }
}

// MARK: - DragEventDelegate
extension PetWindowController: DragEventDelegate {
    func dragStarted(at point: NSPoint) {
        isDragging = true
        petViewModel.onDragStart()
    }

    func dragMoved(to point: NSPoint) {
        // Position updates are handled by DraggedAction polling environment.cursorPosition
        // The mascot system tracks cursor position each tick via NSEvent.mouseLocation
    }

    func dragEnded(at point: NSPoint) {
        isDragging = false
        petViewModel.onDragEnd()
    }

    func tapOccurred(at point: NSPoint) {
        // Handle tap - trigger tap behavior
        petViewModel.onTap()
    }
}

// MARK: - ContextMenuDelegate
extension PetWindowController: ContextMenuDelegate {
    // MARK: Breeding
    func spawnAnotherRequested() {
        guard let instance = petInstance else { return }
        _ = PetManager.shared.spawnChild(from: instance)
    }

    func divideRequested() {
        petViewModel.triggerState(DividingState())
    }

    func pullupRequested() {
        petViewModel.triggerState(PullupState())
    }

    // MARK: Movement
    func walkRequested() {
        petViewModel.triggerState(WalkingState(direction: .randomHorizontal))
    }

    func jumpRequested() {
        petViewModel.triggerState(JumpingState())
    }

    func climbRequested() {
        // Climb the nearest wall
        petViewModel.triggerState(ClimbingState(wall: .left, direction: .up))
    }

    func dangleRequested() {
        petViewModel.triggerState(DanglingState())
    }

    func windowHoldRequested() {
        // Get a window to hold onto
        // When right-clicking, Nano Pet becomes active, so use previous window
        let target: DetectedWindow?
        if WindowDetector.shared.activeAppName == "Nano Pet" {
            target = WindowDetector.shared.previousActiveWindow
        } else {
            target = WindowDetector.shared.activeWindow
        }

        guard let targetDetectedWindow = target ?? WindowDetector.shared.windows.first else {
            print("[WindowHold] No windows available")
            return
        }

        let targetWindow = WindowInfo(
            id: targetDetectedWindow.id,
            frame: targetDetectedWindow.frame,
            topY: targetDetectedWindow.topEdge,
            name: targetDetectedWindow.ownerName
        )

        print("[WindowHold] Triggering hold on window: \(targetDetectedWindow.ownerName)")
        print("[WindowHold] Window frame: \(targetDetectedWindow.frame)")
        print("[WindowHold] Window bottomY: \(targetWindow.bottomY), topY: \(targetWindow.topY), leftX: \(targetWindow.leftX)")
        print("[WindowHold] Screen visibleFrame: \(NSScreen.main?.visibleFrame ?? .zero)")
        print("[WindowHold] Screen full frame: \(NSScreen.main?.frame ?? .zero)")
        print("[WindowHold] Expected pet Y: \(targetWindow.bottomY - 128) (pet top would be at \(targetWindow.bottomY))")

        // WindowHoldState will handle teleporting to the window's left bottom corner
        petViewModel.triggerState(WindowHoldState(window: targetWindow))
    }

    func teleportRequested() {
        print("[Teleport] teleportRequested() called")
        print("[Teleport] activeAppName: '\(WindowDetector.shared.activeAppName)'")
        print("[Teleport] activeWindow: \(WindowDetector.shared.activeWindow?.ownerName ?? "nil")")
        print("[Teleport] previousActiveWindow: \(WindowDetector.shared.previousActiveWindow?.ownerName ?? "nil")")
        print("[Teleport] windows count: \(WindowDetector.shared.windows.count)")

        // When right-clicking, Nano Pet becomes active, so use previous window
        let target: DetectedWindow?
        if WindowDetector.shared.activeAppName == "Nano Pet" {
            target = WindowDetector.shared.previousActiveWindow
            print("[Teleport] Using previousActiveWindow (Nano Pet is active)")
        } else {
            target = WindowDetector.shared.activeWindow
            print("[Teleport] Using activeWindow")
        }

        guard let targetDetectedWindow = target else {
            print("[Teleport] No target window, trying fallback...")
            // Fallback to any window if no active window
            guard let fallback = WindowDetector.shared.windows.first else {
                print("[Teleport] No windows available, returning")
                return
            }
            print("[Teleport] Using fallback window: \(fallback.ownerName)")
            let targetWindow = WindowInfo(
                id: fallback.id,
                frame: fallback.frame,
                topY: fallback.topEdge,
                name: fallback.ownerName
            )
            petViewModel.triggerState(TeleportOutState(targetWindow: targetWindow))
            return
        }

        print("[Teleport] Teleporting to: \(targetDetectedWindow.ownerName)")
        let targetWindow = WindowInfo(
            id: targetDetectedWindow.id,
            frame: targetDetectedWindow.frame,
            topY: targetDetectedWindow.topEdge,
            name: targetDetectedWindow.ownerName
        )
        petViewModel.triggerState(TeleportOutState(targetWindow: targetWindow))
    }

    // MARK: Resting
    func sitRequested() {
        petViewModel.triggerState(SittingState())
    }

    func lieDownRequested() {
        petViewModel.triggerState(LyingState())
    }

    func lookAroundRequested() {
        petViewModel.triggerState(LookAroundState())
    }

    func sitLookUpRequested() {
        petViewModel.triggerState(SitLookUpState())
    }

    func sitStretchRequested() {
        petViewModel.triggerState(SitStretchState())
    }

    // MARK: Routines
    func morningStretchRequested() {
        petViewModel.startRoutine(MorningStretchRoutine())
    }

    func exerciseRequested() {
        petViewModel.startRoutine(ExerciseRoutine())
    }

    func foragingRequested() {
        petViewModel.startRoutine(ForagingRoutine())
    }

    func napRequested() {
        petViewModel.startRoutine(NapRoutine())
    }

    func sunbathingRequested() {
        petViewModel.startRoutine(SunbathingRoutine())
    }

    func deepSleepRequested() {
        petViewModel.startRoutine(DeepSleepRoutine())
    }

    func nightPatrolRequested() {
        petViewModel.startRoutine(NightPatrolRoutine())
    }

    // MARK: Remove
    func removeRequested() {
        guard let instance = petInstance else { return }
        PetManager.shared.removePet(instance)
    }

    func removeAllRequested() {
        PetManager.shared.removeAllPets()
    }
}

// MARK: - Custom Pet Window
class PetWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
