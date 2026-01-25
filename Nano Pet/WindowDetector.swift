//
//  WindowDetector.swift
//  Nano Pet
//
//  窗口感知系统 - 检测其他应用窗口位置
//  单例模式 - 所有宠物共享同一个检测器，减少 CPU 开销
//

import AppKit
import CoreGraphics

// MARK: - Window Info
struct DetectedWindow: Identifiable, Equatable {
    let id: Int
    let name: String
    let ownerName: String
    let frame: CGRect
    let level: Int
    let isOnScreen: Bool

    // 窗口的各个边缘
    var topEdge: CGFloat { frame.maxY }
    var bottomEdge: CGFloat { frame.minY }
    var leftEdge: CGFloat { frame.minX }
    var rightEdge: CGFloat { frame.maxX }

    static func == (lhs: DetectedWindow, rhs: DetectedWindow) -> Bool {
        lhs.id == rhs.id && lhs.frame == rhs.frame
    }
}

// MARK: - Edge Proximity
struct EdgeProximity {
    let window: DetectedWindow
    let edge: WindowEdge
    let distance: CGFloat
    let position: CGFloat  // 沿着边缘的位置
}

enum WindowEdge {
    case top
    case bottom
    case left
    case right
}

// MARK: - Window Detector (Singleton)
@Observable
class WindowDetector {
    // 单例
    static let shared = WindowDetector()

    // 检测到的窗口列表
    private(set) var windows: [DetectedWindow] = []

    // 全屏状态
    private(set) var isFullscreenActive: Bool = false

    // Active app tracking
    private(set) var activeAppName: String = ""
    private(set) var activeWindow: DetectedWindow?
    private(set) var previousActiveAppName: String = ""
    private(set) var previousActiveWindow: DetectedWindow?  // Window before Dream Pet became active

    /// Track if active app changed this tick
    var activeAppDidChange: Bool {
        activeAppName != previousActiveAppName
    }

    // 更新计时器
    private var updateTimer: Timer?

    // 引用计数（有多少宠物在使用）
    private var referenceCount: Int = 0

    // 屏幕边界
    var screenBounds: CGRect {
        NSScreen.main?.visibleFrame ?? .zero
    }

    // 屏幕完整尺寸（包括菜单栏）
    var screenFrame: CGRect {
        NSScreen.main?.frame ?? .zero
    }

    // 主屏幕边界（用于专注模式限制宠物移动范围）
    // NSScreen.screens.first 是主显示器（有菜单栏的那个）
    var primaryScreenBounds: CGRect {
        NSScreen.screens.first?.visibleFrame ?? .zero
    }

    // MARK: - Multi-Screen Support

    /// 根据点坐标找到该点所在的屏幕
    func screenForPoint(_ point: CGPoint) -> NSScreen? {
        return NSScreen.screens.first { $0.frame.contains(point) }
    }

    /// 根据窗口框架找到窗口所在的屏幕（使用窗口中心点判断）
    func screenForWindow(_ windowFrame: CGRect) -> NSScreen? {
        let center = CGPoint(x: windowFrame.midX, y: windowFrame.midY)
        return screenForPoint(center) ?? NSScreen.main
    }

    /// 获取指定点所在屏幕的可见边界
    func screenBoundsForPoint(_ point: CGPoint) -> CGRect {
        return screenForPoint(point)?.visibleFrame ?? screenBounds
    }

    /// 获取指定点所在屏幕的完整框架（包含菜单栏）
    func screenFrameForPoint(_ point: CGPoint) -> CGRect {
        return screenForPoint(point)?.frame ?? screenFrame
    }

    // Dock 信息
    var dockFrame: CGRect {
        guard let screen = NSScreen.main else { return .zero }
        let fullFrame = screen.frame
        let visibleFrame = screen.visibleFrame

        // Dock 在底部
        if visibleFrame.minY > fullFrame.minY {
            return CGRect(
                x: fullFrame.minX,
                y: fullFrame.minY,
                width: fullFrame.width,
                height: visibleFrame.minY - fullFrame.minY
            )
        }
        // Dock 在左侧
        if visibleFrame.minX > fullFrame.minX {
            return CGRect(
                x: fullFrame.minX,
                y: fullFrame.minY,
                width: visibleFrame.minX - fullFrame.minX,
                height: fullFrame.height
            )
        }
        // Dock 在右侧
        if visibleFrame.maxX < fullFrame.maxX {
            return CGRect(
                x: visibleFrame.maxX,
                y: fullFrame.minY,
                width: fullFrame.maxX - visibleFrame.maxX,
                height: fullFrame.height
            )
        }
        return .zero
    }

    private init() {
        // 私有初始化，确保单例
        setupActiveAppTracking()
    }

    // MARK: - Active App Tracking

    private func setupActiveAppTracking() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeAppChanged),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func activeAppChanged(_ notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            let newAppName = app.localizedName ?? ""

            // Save current window as "previous" before switching to Nano Pet
            // This way we remember where user was before right-clicking on pet
            if newAppName == "Nano Pet" && activeWindow != nil {
                previousActiveWindow = activeWindow
                print("[WindowDetector] Saved previousActiveWindow: \(previousActiveWindow?.ownerName ?? "nil")")
            }

            previousActiveAppName = activeAppName
            activeAppName = newAppName
            activeWindow = windows.first { $0.ownerName == activeAppName }
            print("[WindowDetector] activeAppChanged: '\(activeAppName)', window found: \(activeWindow != nil), previousWindow: \(previousActiveWindow?.ownerName ?? "nil")")
        }
    }

    /// Reset change flag after processing
    func acknowledgeActiveAppChange() {
        previousActiveAppName = activeAppName
    }

    // MARK: - Reference Counting

    /// 宠物注册使用（引用计数+1）
    func register() {
        referenceCount += 1
        if referenceCount == 1 {
            startUpdating()
        }
    }

    /// 宠物注销使用（引用计数-1）
    func unregister() {
        referenceCount = max(0, referenceCount - 1)
        if referenceCount == 0 {
            stopUpdating()
        }
    }

    // MARK: - Update Control

    private func startUpdating() {
        // 立即更新一次
        updateWindows()

        // 每0.3秒更新一次（平衡CPU使用与窗口消失响应速度）
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.updateWindows()
        }
    }

    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    // MARK: - Window Detection

    private func updateWindows() {
        guard let windowInfoList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return
        }

        var detectedWindows: [DetectedWindow] = []
        var hasFullscreen = false
        var fullscreenAppName: String = ""

        // 使用主屏幕高度进行坐标转换
        // CGWindow 坐标系统的原点在主屏幕的左上角，而不是 NSScreen.main（最活跃的屏幕）
        // 这对于多屏幕设置至关重要
        let primaryScreen = NSScreen.screens.first
        let screenHeight = primaryScreen?.frame.height ?? 0
        let fullScreenFrame = primaryScreen?.frame ?? screenFrame

        // 方法1：检查主屏幕的 visibleFrame 是否等于 frame（全屏时菜单栏被隐藏）
        // 使用主屏幕而不是 NSScreen.main，因为菜单栏只在主屏幕上
        if let screen = primaryScreen {
            let menuBarHeight = screen.frame.height - screen.visibleFrame.height - screen.visibleFrame.origin.y
            // 如果菜单栏高度接近 0，说明可能是全屏
            if menuBarHeight < 5 && screen.visibleFrame.origin.y < 5 {
                hasFullscreen = true
                fullscreenAppName = "screen-check"
            }
        }

        for windowInfo in windowInfoList {
            guard let windowNumber = windowInfo[kCGWindowNumber as String] as? Int,
                  let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = boundsDict["X"],
                  let y = boundsDict["Y"],
                  let width = boundsDict["Width"],
                  let height = boundsDict["Height"],
                  width > 50, height > 50  // 过滤掉太小的窗口
            else {
                continue
            }

            let ownerName = windowInfo[kCGWindowOwnerName as String] as? String ?? ""
            let windowName = windowInfo[kCGWindowName as String] as? String ?? ""
            let layer = windowInfo[kCGWindowLayer as String] as? Int ?? 0
            let isOnScreen = windowInfo[kCGWindowIsOnscreen as String] as? Bool ?? true

            // 过滤掉自己的窗口和系统UI
            if ownerName == "Nano Pet" || ownerName == "Window Server" {
                continue
            }

            // 过滤掉系统窗口（Dock、控制中心、通知中心等）
            let systemWindows = ["Dock", "程序坞", "Control Center", "控制中心",
                                 "Notification Center", "通知中心"]
            if systemWindows.contains(ownerName) {
                continue
            }

            // 过滤掉菜单栏层级以上的窗口
            if layer > 25 {
                continue
            }

            // 坐标转换：CGWindow 使用左上角为原点，需要转换为左下角
            let convertedY = screenHeight - y - height

            // 检查是否是全屏窗口
            // macOS 全屏应用特征：窗口大小接近或等于屏幕大小，且位置在原点附近
            // 排除程序坞和控制中心
            let windowFrame = CGRect(x: x, y: y, width: width, height: height)
            let isFullscreenSize = windowFrame.width >= fullScreenFrame.width - 1 &&
                                   windowFrame.height >= fullScreenFrame.height - 50
            let isAtOrigin = abs(x) <= 1 && abs(y) <= 50

            if isFullscreenSize && isAtOrigin && ownerName != "Dock" && ownerName != "Control Center" && ownerName != "程序坞" {
                hasFullscreen = true
                fullscreenAppName = ownerName
            }

            let window = DetectedWindow(
                id: windowNumber,
                name: windowName,
                ownerName: ownerName,
                frame: CGRect(x: x, y: convertedY, width: width, height: height),
                level: layer,
                isOnScreen: isOnScreen
            )

            detectedWindows.append(window)
        }

        windows = detectedWindows

        // 只在全屏状态变化时打印日志
        if hasFullscreen != isFullscreenActive {
            if hasFullscreen {
                print("[WindowDetector] Fullscreen entered: \(fullscreenAppName)")
            } else {
                print("[WindowDetector] Fullscreen exited")
            }
        }
        isFullscreenActive = hasFullscreen

        // Refresh activeWindow when windows list updates
        if !activeAppName.isEmpty {
            let oldWindow = activeWindow?.ownerName ?? "nil"
            activeWindow = windows.first { $0.ownerName == activeAppName }
            let newWindow = activeWindow?.ownerName ?? "nil"
            if oldWindow != newWindow {
                print("[WindowDetector] updateWindows: activeWindow changed from '\(oldWindow)' to '\(newWindow)' for app '\(activeAppName)'")
            }
        }

        // Also refresh previousActiveWindow if we have a previous app name
        if !previousActiveAppName.isEmpty && previousActiveAppName != "Nano Pet" {
            previousActiveWindow = windows.first { $0.ownerName == previousActiveAppName }
        }
    }

    // MARK: - Collision Detection (窗口避让)

    /// 检查宠物是否与任何窗口重叠
    /// 如果 allowPetsInWindows 设置为 true，则始终返回 false（不进行避让）
    func isOverlappingWindow(petFrame: CGRect) -> Bool {
        // 如果允许宠物在窗口内显示，则跳过碰撞检测
        if AppSettings.shared.allowPetsInWindows {
            return false
        }

        for window in windows {
            if petFrame.intersects(window.frame) {
                return true
            }
        }
        return false
    }

    /// 查找最近的安全位置（不与窗口重叠）
    func findSafePosition(from petFrame: CGRect, preferredDirection: WalkDirection? = nil) -> CGPoint? {
        guard isOverlappingWindow(petFrame: petFrame) else {
            return nil  // 已经安全
        }

        // 找到所有重叠的窗口
        let overlappingWindows = windows.filter { petFrame.intersects($0.frame) }

        guard let firstWindow = overlappingWindows.first else {
            return nil
        }

        let petCenter = CGPoint(x: petFrame.midX, y: petFrame.midY)
        let petWidth = petFrame.width
        let petHeight = petFrame.height

        // 计算四个方向的安全位置
        var candidates: [(point: CGPoint, distance: CGFloat)] = []

        // 窗口左侧
        let leftX = firstWindow.leftEdge - petWidth
        if leftX >= screenBounds.minX {
            let point = CGPoint(x: leftX, y: petFrame.minY)
            let dist = abs(petCenter.x - (leftX + petWidth/2))
            candidates.append((point, dist))
        }

        // 窗口右侧
        let rightX = firstWindow.rightEdge
        if rightX + petWidth <= screenBounds.maxX {
            let point = CGPoint(x: rightX, y: petFrame.minY)
            let dist = abs(petCenter.x - (rightX + petWidth/2))
            candidates.append((point, dist))
        }

        // 窗口上方
        let topY = firstWindow.topEdge
        if topY + petHeight <= screenBounds.maxY {
            let point = CGPoint(x: petFrame.minX, y: topY)
            let dist = abs(petCenter.y - (topY + petHeight/2))
            candidates.append((point, dist))
        }

        // 窗口下方（通常是屏幕底部）
        let bottomY = firstWindow.bottomEdge - petHeight
        if bottomY >= screenBounds.minY {
            let point = CGPoint(x: petFrame.minX, y: bottomY)
            let dist = abs(petCenter.y - (bottomY + petHeight/2))
            candidates.append((point, dist))
        }

        // 根据偏好方向排序
        if let direction = preferredDirection {
            switch direction {
            case .left:
                candidates.sort { $0.point.x < $1.point.x }
            case .right:
                candidates.sort { $0.point.x > $1.point.x }
            case .up, .down:
                // For vertical directions, use default distance sorting
                candidates.sort { $0.distance < $1.distance }
            }
        } else {
            // 默认选择最近的
            candidates.sort { $0.distance < $1.distance }
        }

        return candidates.first?.point
    }

    /// 检查目标位置是否安全（用于行走前的预判）
    func isPositionSafe(_ position: CGPoint, petSize: CGSize) -> Bool {
        let petFrame = CGRect(origin: position, size: petSize)

        // 检查是否在屏幕内
        guard screenBounds.contains(petFrame) else {
            return false
        }

        // 检查是否与窗口重叠
        return !isOverlappingWindow(petFrame: petFrame)
    }

    /// 查找沿窗口边缘的行走路径
    func findEdgePath(from petFrame: CGRect, direction: WalkDirection) -> CGPoint? {
        let petBottom = petFrame.minY

        // 找到宠物下方的窗口
        guard let windowBelow = findWindowBelow(petFrame: petFrame, maxDistance: 10) else {
            return nil
        }

        // 沿着窗口顶部边缘行走
        let newX: CGFloat
        switch direction {
        case .left:
            newX = max(windowBelow.leftEdge, petFrame.minX - 2)
        case .right:
            newX = min(windowBelow.rightEdge - petFrame.width, petFrame.minX + 2)
        case .up, .down:
            // Vertical directions don't apply to edge walking
            return nil
        }

        return CGPoint(x: newX, y: petBottom)
    }

    // MARK: - Proximity Detection

    /// 查找宠物附近的窗口边缘
    func findNearbyEdges(petFrame: CGRect, maxDistance: CGFloat? = nil) -> [EdgeProximity] {
        let effectiveMaxDistance = maxDistance ?? ScreenScaling.detectionThreshold(forPoint: petFrame.origin)
        var proximities: [EdgeProximity] = []

        let petCenterX = petFrame.midX
        let petCenterY = petFrame.midY
        let petBottom = petFrame.minY
        let petLeft = petFrame.minX
        let petRight = petFrame.maxX

        for window in windows {
            // 检查窗口顶部边缘（宠物可以站在上面）
            if petBottom >= window.topEdge - effectiveMaxDistance &&
               petBottom <= window.topEdge + effectiveMaxDistance &&
               petCenterX >= window.leftEdge &&
               petCenterX <= window.rightEdge {

                let distance = abs(petBottom - window.topEdge)
                proximities.append(EdgeProximity(
                    window: window,
                    edge: .top,
                    distance: distance,
                    position: petCenterX - window.leftEdge
                ))
            }

            // 检查窗口左侧边缘（宠物可以攀爬）
            if petRight >= window.leftEdge - effectiveMaxDistance &&
               petRight <= window.leftEdge + effectiveMaxDistance &&
               petCenterY >= window.bottomEdge &&
               petCenterY <= window.topEdge {

                let distance = abs(petRight - window.leftEdge)
                proximities.append(EdgeProximity(
                    window: window,
                    edge: .left,
                    distance: distance,
                    position: petCenterY - window.bottomEdge
                ))
            }

            // 检查窗口右侧边缘
            if petLeft >= window.rightEdge - effectiveMaxDistance &&
               petLeft <= window.rightEdge + effectiveMaxDistance &&
               petCenterY >= window.bottomEdge &&
               petCenterY <= window.topEdge {

                let distance = abs(petLeft - window.rightEdge)
                proximities.append(EdgeProximity(
                    window: window,
                    edge: .right,
                    distance: distance,
                    position: petCenterY - window.bottomEdge
                ))
            }
        }

        // 按距离排序
        return proximities.sorted { $0.distance < $1.distance }
    }

    /// 查找宠物下方可以站立的窗口
    func findWindowBelow(petFrame: CGRect, maxDistance: CGFloat? = nil) -> DetectedWindow? {
        let effectiveMaxDistance = maxDistance ?? ScreenScaling.detectionThreshold(forPoint: petFrame.origin)
        let petCenterX = petFrame.midX
        let petBottom = petFrame.minY

        var closestWindow: DetectedWindow?
        var closestDistance: CGFloat = effectiveMaxDistance

        for window in windows {
            // 检查宠物是否在窗口的水平范围内
            guard petCenterX >= window.leftEdge && petCenterX <= window.rightEdge else {
                continue
            }

            // 检查窗口顶部是否在宠物下方
            let distance = petBottom - window.topEdge
            if distance >= 0 && distance < closestDistance {
                closestDistance = distance
                closestWindow = window
            }
        }

        return closestWindow
    }

    /// 查找宠物上方的窗口（用于 peek from bottom）
    func findWindowAbove(petFrame: CGRect, maxDistance: CGFloat? = nil) -> DetectedWindow? {
        let effectiveMaxDistance = maxDistance ?? ScreenScaling.windowSearchRadius(forPoint: petFrame.origin)
        let petCenterX = petFrame.midX
        let petTop = petFrame.maxY

        var closestWindow: DetectedWindow?
        var closestDistance: CGFloat = effectiveMaxDistance

        for window in windows {
            // 检查宠物是否在窗口的水平范围内
            guard petCenterX >= window.leftEdge && petCenterX <= window.rightEdge else {
                continue
            }

            // 检查窗口底部是否在宠物上方
            let distance = window.bottomEdge - petTop
            if distance >= 0 && distance < closestDistance {
                closestDistance = distance
                closestWindow = window
            }
        }

        return closestWindow
    }

    /// 查找附近可以从底部探头的窗口边缘
    func findNearbyBottomEdges(petFrame: CGRect, maxDistance: CGFloat? = nil) -> [EdgeProximity] {
        let effectiveMaxDistance = maxDistance ?? ScreenScaling.windowSearchRadius(forPoint: petFrame.origin)
        var proximities: [EdgeProximity] = []

        let petCenterX = petFrame.midX
        let petTop = petFrame.maxY

        // Use screen-aware threshold based on pet position
        let tolerance = ScreenScaling.detectionThreshold(forPoint: petFrame.origin)

        for window in windows {
            // 检查宠物是否在窗口的水平范围内（有一定容差）
            let horizontalOverlap = petCenterX >= window.leftEdge - tolerance && petCenterX <= window.rightEdge + tolerance

            guard horizontalOverlap else {
                continue
            }

            // 检查窗口底部边缘是否在宠物上方可达范围内
            let distance = window.bottomEdge - petTop
            if distance >= 0 && distance <= effectiveMaxDistance {
                proximities.append(EdgeProximity(
                    window: window,
                    edge: .bottom,
                    distance: distance,
                    position: petCenterX - window.leftEdge
                ))
            }
        }

        return proximities.sorted { $0.distance < $1.distance }
    }

    /// 检查宠物是否在屏幕边缘
    func checkScreenEdge(petFrame: CGRect, threshold: CGFloat = 10) -> WindowEdge? {
        if petFrame.minX <= screenBounds.minX + threshold {
            return .left
        }
        if petFrame.maxX >= screenBounds.maxX - threshold {
            return .right
        }
        if petFrame.minY <= screenBounds.minY + threshold {
            return .bottom
        }
        if petFrame.maxY >= screenBounds.maxY - threshold {
            return .top
        }
        return nil
    }

    /// 检查宠物是否靠近 Dock
    func isNearDock(petFrame: CGRect, threshold: CGFloat = 30) -> Bool {
        guard dockFrame.width > 0 || dockFrame.height > 0 else {
            return false
        }

        let expandedDock = dockFrame.insetBy(dx: -threshold, dy: -threshold)
        return petFrame.intersects(expandedDock)
    }
}
