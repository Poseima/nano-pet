//
//  PetManager.swift
//  Nano Pet
//
//  多宠物管理器 - 管理桌面上的多个宠物
//

import Foundation
import AppKit
import SwiftUI
import Combine

// MARK: - Pet Instance

class PetInstance: Identifiable, ObservableObject {
    let id: UUID
    let petName: String       // 角色名，如 "Agumon"
    let displayName: String   // 显示名，如 "Agumon #1"
    let windowController: PetWindowController
    @Published var isVisible: Bool = true

    init(petName: String, displayName: String) {
        self.id = UUID()
        self.petName = petName
        self.displayName = displayName
        self.windowController = PetWindowController(petName: petName)
        // Set reference for context menu
        self.windowController.petInstance = self
        // 设置宠物身份标识，用于日志记录
        self.windowController.setPetIdentifier(displayName)
    }

    // 用于恢复已保存的宠物
    init(id: UUID, petName: String, displayName: String) {
        self.id = id
        self.petName = petName
        self.displayName = displayName
        self.windowController = PetWindowController(petName: petName)
        // Set reference for context menu
        self.windowController.petInstance = self
        // 设置宠物身份标识，用于日志记录
        self.windowController.setPetIdentifier(displayName)
    }

    func show() {
        windowController.showWindow(nil)
        isVisible = true
    }

    func hide() {
        windowController.close()
        isVisible = false
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func triggerRandomAction() {
        windowController.triggerRandomAction()
    }

    func triggerDivide() {
        windowController.divideRequested()
    }

    /// 强制清理窗口，确保窗口立即从屏幕移除
    func forceCleanup() {
        windowController.window?.orderOut(nil)  // 立即从屏幕移除
        windowController.window?.close()
        windowController.close()
        isVisible = false
    }
}

// MARK: - Spawn Source

/// 生成来源枚举，用于调试和追踪
enum SpawnSource: String {
    case menuAddNew = "menu_add_new"
    case menuRandomBirth = "menu_random_birth"
    case autoSpawnTimer = "auto_spawn_timer"
    case dividingState = "dividing_state"
    case pullupState = "pullup_state"
    case contextMenu = "context_menu"
    case restore = "restore"
    case replaceRandom = "replace_random"
}

// MARK: - Pet Manager

@Observable
class PetManager {
    static let shared = PetManager()

    // 所有宠物实例
    private(set) var pets: [PetInstance] = []

    // 最大宠物数量
    let maxPets = 256

    // 默认宠物名称
    private let defaultNames = ["小橘", "皮卡丘", "伊布", "小白", "小黑"]

    // MARK: - Spawn Protection

    /// 生成锁，防止同时多次生成
    private var isSpawning = false

    /// 上次生成时间，用于冷却
    private var lastSpawnTime: Date = .distantPast

    /// 冷却时间（秒）
    private let spawnCooldown: TimeInterval = 2.0

    init() {}

    // MARK: - Pet Management

    /// 统一的生成入口 - 所有生成必须通过此方法（除了恢复状态）
    /// - Parameters:
    ///   - petName: 宠物角色名
    ///   - source: 生成来源
    ///   - position: 可选的初始位置
    ///   - skipCooldown: 是否跳过冷却检查（用于恢复和替换）
    /// - Returns: 新创建的宠物实例，如果失败返回 nil
    @discardableResult
    private func spawnPet(petName: String, from source: SpawnSource, position: CGPoint? = nil, skipCooldown: Bool = false) -> PetInstance? {
        // 检查是否正在生成
        guard !isSpawning else {
            print("[PetManager] Spawn blocked: already spawning (source: \(source.rawValue))")
            return nil
        }

        // 检查冷却（恢复和替换操作跳过冷却）
        if !skipCooldown {
            let now = Date()
            guard now.timeIntervalSince(lastSpawnTime) >= spawnCooldown else {
                print("[PetManager] Spawn blocked: cooldown active (source: \(source.rawValue))")
                return nil
            }
        }

        // 检查容量
        guard canSpawn() else {
            print("[PetManager] Spawn blocked: max pets reached (source: \(source.rawValue))")
            return nil
        }

        isSpawning = true
        defer { isSpawning = false }

        // 记录生成来源（用于调试）
        print("[PetManager] Spawning pet '\(petName)' from: \(source.rawValue)")

        // 计算同角色的编号
        let sameCount = pets.filter { $0.petName == petName }.count
        let displayName = "\(petName) #\(sameCount + 1)"

        let pet = PetInstance(petName: petName, displayName: displayName)
        pets.append(pet)
        pet.show()

        // 设置位置 - 必须用 setPosition 同时更新窗口和 brain 内部位置
        if let pos = position {
            pet.windowController.setPosition(pos)
        } else if pets.count > 1 {
            // 随机偏移位置避免重叠
            if let window = pet.windowController.window {
                var origin = window.frame.origin
                origin.x += CGFloat(pets.count - 1) * 100
                pet.windowController.setPosition(origin)
            }
        }

        // 更新冷却时间
        lastSpawnTime = Date()

        // 自动保存状态
        savePetStates()

        // 日志记录生成成功
        print("[PetManager] [\(displayName)] 宠物已创建 (id: \(pet.id.uuidString.prefix(8)), 来源: \(source.rawValue), 当前数量: \(pets.count))")

        return pet
    }

    /// 添加新宠物（指定角色名）- 通过菜单添加
    @discardableResult
    func addPet(petName: String) -> PetInstance? {
        return spawnPet(petName: petName, from: .menuAddNew)
    }

    /// 添加新宠物（指定位置）- 用于替换等场景
    @discardableResult
    func addPet(petName: String, at position: CGPoint, source: SpawnSource = .replaceRandom) -> PetInstance? {
        return spawnPet(petName: petName, from: source, position: position, skipCooldown: true)
    }

    /// 移除宠物
    func removePet(_ pet: PetInstance) {
        print("[PetManager] [\(pet.displayName)] 宠物将被删除 (id: \(pet.id.uuidString.prefix(8)))")
        pet.hide()
        pets.removeAll { $0.id == pet.id }
        savePetStates()
        print("[PetManager] 宠物已删除，当前数量: \(pets.count)")
    }

    /// 移除所有宠物
    func removeAllPets() {
        print("[PetManager] 删除所有宠物，当前数量: \(pets.count)")
        for pet in pets {
            print("[PetManager]   - [\(pet.displayName)] 已删除")
            pet.hide()
        }
        pets.removeAll()
        savePetStates()
        print("[PetManager] 所有宠物已删除")
    }

    /// 显示所有宠物
    func showAllPets() {
        for pet in pets {
            pet.show()
        }
    }

    /// 隐藏所有宠物
    func hideAllPets() {
        for pet in pets {
            pet.hide()
        }
    }

    /// 触发所有宠物的随机行为
    func triggerRandomActionForAll() {
        for pet in pets {
            pet.triggerRandomAction()
        }
    }

    /// 随机选择一个可见宠物进行分身
    func triggerRandomDivide() {
        let visiblePets = pets.filter { $0.isVisible }
        if let randomPet = visiblePets.randomElement() {
            randomPet.triggerDivide()
        }
    }

    /// 将所有宠物移动到程序坞上方或屏幕底部（专注模式）
    func moveAllPetsToDockOrBottom() {
        let visiblePets = pets.filter { $0.isVisible }
        guard !visiblePets.isEmpty else {
            print("[PetManager] moveAllPetsToDockOrBottom: No visible pets")
            return
        }

        let detector = WindowDetector.shared
        let dockFrame = detector.dockFrame
        let screenBounds = detector.screenBounds

        print("[PetManager] moveAllPetsToDockOrBottom called")
        print("[PetManager] dockFrame: \(dockFrame), screenBounds: \(screenBounds)")

        // 计算目标 Y 坐标
        // 如果 Dock 在底部（dockFrame 有高度且在屏幕底部）
        // 否则使用屏幕可见区域的底部
        let targetY: CGFloat
        if dockFrame.height > 10 {
            // Dock 存在，站在 Dock 上方
            targetY = dockFrame.maxY
            print("[PetManager] Dock detected at bottom, targetY = \(targetY)")
        } else {
            // 没有 Dock 或 Dock 隐藏，使用屏幕底部
            targetY = screenBounds.minY
            print("[PetManager] No Dock, using screen bottom, targetY = \(targetY)")
        }

        // 计算宠物间距和起始位置 (5% of screen width, minimum 80px)
        let petSpacing: CGFloat = max(80, (NSScreen.main?.visibleFrame.width ?? 1440) * 0.05)
        let totalWidth = CGFloat(visiblePets.count - 1) * petSpacing
        let startX = screenBounds.midX - totalWidth / 2

        // 移动每个宠物到目标位置
        for (index, pet) in visiblePets.enumerated() {
            let targetX = startX + CGFloat(index) * petSpacing
            let targetPosition = CGPoint(x: targetX, y: targetY)

            print("[PetManager] Moving pet \(pet.displayName) to \(targetPosition)")

            // 使用 setPosition 更新 brain 内部位置和窗口位置
            pet.windowController.setPosition(targetPosition)
        }

        savePetStates()
        print("[PetManager] moveAllPetsToDockOrBottom completed")
    }

    /// Replace a single pet with a random character
    func replacePetRandomly(_ pet: PetInstance) {
        let allCharacters = AssetPackManager.shared.getAllCharacters()
        guard !allCharacters.isEmpty else { return }
        guard let randomCharacter = allCharacters.randomElement() else { return }

        // Get position before removing
        let position = pet.windowController.window?.frame.origin ?? CGPoint(x: 100, y: 100)
        let wasVisible = pet.isVisible

        // Remove old pet
        pet.forceCleanup()
        pets.removeAll { $0.id == pet.id }

        // Create new pet at same position
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let newPet = self.addPet(petName: randomCharacter, at: position, source: .replaceRandom) {
                if !wasVisible {
                    newPet.hide()
                }
            }
            self.savePetStates()
        }
    }

    /// 随机替换所有宠物的角色
    func replaceAllPetsRandomly() {
        let allCharacters = AssetPackManager.shared.getAllCharacters()
        guard !allCharacters.isEmpty else { return }

        // 收集所有当前宠物的信息（不依赖 window 存在）
        var petsToReplace: [(position: CGPoint, isVisible: Bool)] = []
        for pet in pets {
            // 使用 window 位置，如果 window 不存在则使用默认位置
            let position = pet.windowController.window?.frame.origin ?? CGPoint(x: 100, y: 100)
            petsToReplace.append((position: position, isVisible: pet.isVisible))
        }

        // 强制关闭所有窗口并确保清理
        for pet in pets {
            pet.forceCleanup()
        }
        pets.removeAll()

        // 延迟创建新宠物，确保旧窗口完全释放
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            for info in petsToReplace {
                // 随机选择一个角色
                guard let randomCharacter = allCharacters.randomElement() else { continue }

                // 使用带位置的 addPet 方法（跳过冷却）
                if let newPet = self.addPet(petName: randomCharacter, at: info.position, source: .replaceRandom) {
                    // 恢复可见性
                    if !info.isVisible {
                        newPet.hide()
                    }
                }
            }

            self.savePetStates()
        }
    }

    /// 根据ID获取宠物
    func getPet(by id: UUID) -> PetInstance? {
        pets.first { $0.id == id }
    }

    // MARK: - Breeding System (per SHIMEJI_ANIMATION_SYSTEM_SPEC.md Section 9)

    /// Check if a new mascot can be spawned
    func canSpawn() -> Bool {
        return pets.count < maxPets
    }

    /// Spawn a child mascot (for breeding behaviors like divide/pullup)
    /// - Parameters:
    ///   - parent: Parent pet instance
    ///   - offset: Spawn offset from parent position
    ///   - source: Spawn source for tracking
    /// - Returns: New child pet instance, or nil if blocked by cooldown/lock/capacity
    @discardableResult
    func spawnChild(from parent: PetInstance, offset: CGPoint = CGPoint(x: 64, y: 0), source: SpawnSource = .dividingState) -> PetInstance? {
        print("[PetManager] [\(parent.displayName)] 请求生成子宠物 (来源: \(source.rawValue))")

        // Get parent position
        guard let parentWindow = parent.windowController.window else {
            print("[PetManager] [\(parent.displayName)] spawnChild blocked: no parent window")
            return nil
        }
        let parentPosition = parentWindow.frame.origin
        let childPosition = CGPoint(
            x: parentPosition.x + offset.x,
            y: parentPosition.y + offset.y
        )

        // 使用统一入口生成
        let child = spawnPet(petName: parent.petName, from: source, position: childPosition)
        if let child = child {
            print("[PetManager] [\(parent.displayName)] 成功生成子宠物: \(child.displayName)")
        }
        return child
    }

    /// Generate display name for a child mascot
    private func generateChildName(for petName: String) -> String {
        let sameCount = pets.filter { $0.petName == petName }.count
        return "\(petName) #\(sameCount + 1)"
    }

    // MARK: - Persistence

    /// 保存宠物状态
    func savePetStates() {
        let states = pets.map { pet -> [String: Any] in
            return [
                "id": pet.id.uuidString,
                "petName": pet.petName,
                "displayName": pet.displayName,
                "isVisible": pet.isVisible,
                "x": pet.windowController.window?.frame.origin.x ?? 0,
                "y": pet.windowController.window?.frame.origin.y ?? 0
            ]
        }
        UserDefaults.standard.set(states, forKey: "pet_states")
    }

    /// 恢复宠物状态
    func restorePetStates() {
        guard let states = UserDefaults.standard.array(forKey: "pet_states") as? [[String: Any]] else {
            return
        }

        for state in states {
            guard let idString = state["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let displayName = state["displayName"] as? String else { continue }

            // Support both old "shimejiName" and new "petName" keys
            let petName = (state["petName"] as? String) ?? (state["shimejiName"] as? String) ?? "Agumon"

            let isVisible = state["isVisible"] as? Bool ?? true
            let x = state["x"] as? CGFloat ?? 0
            let y = state["y"] as? CGFloat ?? 0

            // 创建宠物实例
            let pet = PetInstance(id: id, petName: petName, displayName: displayName)
            pets.append(pet)

            // 设置位置
            if let window = pet.windowController.window {
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }

            // 根据保存的状态显示或隐藏
            if isVisible {
                pet.show()
            } else {
                pet.isVisible = false
            }
        }
    }
}

// MARK: - Pet Menu Builder

extension PetManager {
    /// 构建宠物控制菜单
    func buildPetMenu() -> NSMenu {
        let menu = NSMenu()

        // 宠物列表
        if !pets.isEmpty {
            for pet in pets {
                let item = NSMenuItem(
                    title: pet.displayName,
                    action: #selector(AppDelegate.togglePetFromMenu(_:)),
                    keyEquivalent: ""
                )
                item.target = AppDelegate.shared
                item.representedObject = pet.id
                item.state = pet.isVisible ? .on : .off

                // 添加子菜单
                let submenu = NSMenu()

                let showItem = NSMenuItem(
                    title: pet.isVisible ? "隐藏" : "显示",
                    action: #selector(AppDelegate.togglePetFromMenu(_:)),
                    keyEquivalent: ""
                )
                showItem.target = AppDelegate.shared
                showItem.representedObject = pet.id
                submenu.addItem(showItem)

                let actionItem = NSMenuItem(
                    title: "随机行为",
                    action: #selector(AppDelegate.triggerPetAction(_:)),
                    keyEquivalent: ""
                )
                actionItem.target = AppDelegate.shared
                actionItem.representedObject = pet.id
                submenu.addItem(actionItem)

                submenu.addItem(NSMenuItem.separator())

                let removeItem = NSMenuItem(
                    title: "移除",
                    action: #selector(AppDelegate.removePetFromMenu(_:)),
                    keyEquivalent: ""
                )
                removeItem.target = AppDelegate.shared
                removeItem.representedObject = pet.id
                submenu.addItem(removeItem)

                item.submenu = submenu
                menu.addItem(item)
            }

            menu.addItem(NSMenuItem.separator())
        }

        // 添加新宠物
        if pets.count < maxPets {
            let addItem = NSMenuItem(
                title: "添加新宠物",
                action: #selector(AppDelegate.addNewPet),
                keyEquivalent: ""
            )
            addItem.target = AppDelegate.shared
            menu.addItem(addItem)
        }

        // 全部显示/隐藏
        if !pets.isEmpty {
            let allVisibleItem = NSMenuItem(
                title: "显示全部",
                action: #selector(AppDelegate.showAllPetsAction),
                keyEquivalent: ""
            )
            allVisibleItem.target = AppDelegate.shared
            menu.addItem(allVisibleItem)

            let allHiddenItem = NSMenuItem(
                title: "隐藏全部",
                action: #selector(AppDelegate.hideAllPetsAction),
                keyEquivalent: ""
            )
            allHiddenItem.target = AppDelegate.shared
            menu.addItem(allHiddenItem)
        }

        return menu
    }
}
