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
            let y = screenFrame.minY + screenFrame.height * 0.05  // 5% from bottom
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

    // MARK: Replace
    func randomReplaceRequested() {
        guard let instance = petInstance else { return }
        PetManager.shared.replacePetRandomly(instance)
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
