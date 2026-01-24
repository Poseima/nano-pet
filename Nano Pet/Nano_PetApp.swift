//
//  Nano_PetApp.swift
//  Nano Pet
//
//  Created by MRS on 2025/12/27.
//

import SwiftUI
import AppKit

@main
struct Nano_PetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 使用 Settings 场景作为占位，实际UI在菜单栏
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    private var statusItem: NSStatusItem!
    private let petManager = PetManager.shared
    private var nestWindow: NSWindow?
    private var aiStudioWindow: NSWindow?
    private var assetImportWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var autoSpawnTimer: Timer?
    private var randomReplaceTimer: Timer?
    private var fullscreenCheckTimer: Timer?
    private var wasHiddenByFullscreen: Bool = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // 隐藏 Dock 图标，变成纯菜单栏应用
        NSApp.setActivationPolicy(.accessory)

        // 设置菜单栏图标
        setupMenuBar()

        // 如果之前启用了随机替换，启动定时器
        if AppSettings.shared.randomReplaceEnabled {
            startRandomReplace()
        }

        // 如果之前启用了自动生成，启动定时器
        if AppSettings.shared.autoSpawnEnabled {
            startAutoSpawn()
        }

        // 恢复或创建桌面宠物
        petManager.restorePetStates()

        // 如果启用了全屏隐藏，启动监控
        if AppSettings.shared.hideOnFullscreen {
            startFullscreenMonitor()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 保存宠物状态
        petManager.savePetStates()
    }

    // MARK: - Menu Bar Setup
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Use custom menu bar icon (template image)
            button.image = NSImage(named: "MenuBarIcon")
        }

        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()

        // 标题
        let titleItem = NSMenuItem(title: "Nano Pet", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        // 小窝
        let nestItem = NSMenuItem(title: "打开小窝...", action: #selector(openNest), keyEquivalent: "")
        nestItem.target = self
        menu.addItem(nestItem)

        // AI 素材工作室
        let aiStudioItem = NSMenuItem(title: "AI 素材工作室...", action: #selector(openAIStudio), keyEquivalent: "")
        aiStudioItem.target = self
        menu.addItem(aiStudioItem)

        menu.addItem(NSMenuItem.separator())

        // 禁用跳跃 (toggle)
        let jumpTitle = AppSettings.shared.disableJumping ? "启用跳跃" : "禁用跳跃"
        let jumpItem = NSMenuItem(title: jumpTitle, action: #selector(toggleJumping), keyEquivalent: "")
        jumpItem.target = self
        menu.addItem(jumpItem)

        // 隐藏宠物 (toggle)
        let hideTitle = AppSettings.shared.petsHidden ? "显示宠物" : "隐藏宠物"
        let hideItem = NSMenuItem(title: hideTitle, action: #selector(toggleHidePets), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)

        // 全屏隐藏 (toggle)
        let fullscreenHideTitle = AppSettings.shared.hideOnFullscreen ? "✓ 全屏隐藏" : "全屏隐藏"
        let fullscreenHideItem = NSMenuItem(title: fullscreenHideTitle, action: #selector(toggleHideOnFullscreen), keyEquivalent: "")
        fullscreenHideItem.target = self
        menu.addItem(fullscreenHideItem)

        // 宠物回家
        let goHomeItem = NSMenuItem(title: "宠物回家", action: #selector(petsGoHome), keyEquivalent: "")
        goHomeItem.target = self
        menu.addItem(goHomeItem)

        // 随机诞生
        let randomBirthItem = NSMenuItem(title: "随机诞生", action: #selector(randomBirth), keyEquivalent: "")
        randomBirthItem.target = self
        menu.addItem(randomBirthItem)

        // 自动分身 (submenu with toggle + custom interval)
        let autoSpawnItem = NSMenuItem(title: "自动分身", action: nil, keyEquivalent: "")
        let autoSpawnMenu = NSMenu()

        let autoToggleTitle = AppSettings.shared.autoSpawnEnabled ? "停止自动分身" : "开始自动分身"
        let autoToggleItem = NSMenuItem(title: autoToggleTitle, action: #selector(toggleAutoSpawn), keyEquivalent: "")
        autoToggleItem.target = self
        autoSpawnMenu.addItem(autoToggleItem)

        autoSpawnMenu.addItem(NSMenuItem.separator())

        // 显示当前间隔
        let interval = AppSettings.shared.autoSpawnInterval
        let intervalText = interval >= 60 ? "\(Int(interval / 60))分钟" : "\(Int(interval))秒"
        let currentIntervalItem = NSMenuItem(title: "当前间隔: \(intervalText)", action: nil, keyEquivalent: "")
        currentIntervalItem.isEnabled = false
        autoSpawnMenu.addItem(currentIntervalItem)

        // 设置间隔（弹出输入框）
        let setIntervalItem = NSMenuItem(title: "设置间隔...", action: #selector(showSetIntervalDialog), keyEquivalent: "")
        setIntervalItem.target = self
        autoSpawnMenu.addItem(setIntervalItem)

        autoSpawnItem.submenu = autoSpawnMenu
        menu.addItem(autoSpawnItem)

        // 随机替换 (submenu with toggle + custom interval)
        let randomReplaceItem = NSMenuItem(title: "随机替换", action: nil, keyEquivalent: "")
        let randomReplaceMenu = NSMenu()

        let replaceToggleTitle = AppSettings.shared.randomReplaceEnabled ? "停止随机替换" : "开始随机替换"
        let replaceToggleItem = NSMenuItem(title: replaceToggleTitle, action: #selector(toggleRandomReplace), keyEquivalent: "")
        replaceToggleItem.target = self
        randomReplaceMenu.addItem(replaceToggleItem)

        randomReplaceMenu.addItem(NSMenuItem.separator())

        // 显示当前间隔
        let replaceInterval = AppSettings.shared.randomReplaceInterval
        let replaceIntervalText = replaceInterval >= 60 ? "\(Int(replaceInterval / 60))分钟" : "\(Int(replaceInterval))秒"
        let currentReplaceIntervalItem = NSMenuItem(title: "当前间隔: \(replaceIntervalText)", action: nil, keyEquivalent: "")
        currentReplaceIntervalItem.isEnabled = false
        randomReplaceMenu.addItem(currentReplaceIntervalItem)

        // 设置间隔
        let setReplaceIntervalItem = NSMenuItem(title: "设置间隔...", action: #selector(showSetRandomReplaceIntervalDialog), keyEquivalent: "")
        setReplaceIntervalItem.target = self
        randomReplaceMenu.addItem(setReplaceIntervalItem)

        randomReplaceItem.submenu = randomReplaceMenu
        menu.addItem(randomReplaceItem)

        menu.addItem(NSMenuItem.separator())

        // === 行为模式子菜单 ===
        let behaviorModeItem = NSMenuItem(title: "行为模式", action: nil, keyEquivalent: "")
        let behaviorModeMenu = NSMenu()

        let randomModeItem = NSMenuItem(
            title: AppSettings.shared.behaviorMode == .random ? "✓ 随机行为" : "随机行为",
            action: #selector(setBehaviorModeRandom),
            keyEquivalent: ""
        )
        randomModeItem.target = self
        behaviorModeMenu.addItem(randomModeItem)

        let focusModeItem = NSMenuItem(
            title: AppSettings.shared.behaviorMode == .focus ? "✓ 专注模式" : "专注模式",
            action: #selector(setBehaviorModeFocus),
            keyEquivalent: ""
        )
        focusModeItem.target = self
        behaviorModeMenu.addItem(focusModeItem)

        behaviorModeItem.submenu = behaviorModeMenu
        menu.addItem(behaviorModeItem)

        // === 动作频率子菜单 ===
        let actionSpeedItem = NSMenuItem(title: "动作频率", action: nil, keyEquivalent: "")
        let actionSpeedMenu = NSMenu()

        let slowItem = NSMenuItem(
            title: AppSettings.shared.actionSpeed == .slow ? "✓ 慢" : "慢",
            action: #selector(setActionSpeedSlow),
            keyEquivalent: ""
        )
        slowItem.target = self
        actionSpeedMenu.addItem(slowItem)

        let mediumItem = NSMenuItem(
            title: AppSettings.shared.actionSpeed == .medium ? "✓ 中等" : "中等",
            action: #selector(setActionSpeedMedium),
            keyEquivalent: ""
        )
        mediumItem.target = self
        actionSpeedMenu.addItem(mediumItem)

        let fastItem = NSMenuItem(
            title: AppSettings.shared.actionSpeed == .fast ? "✓ 快" : "快",
            action: #selector(setActionSpeedFast),
            keyEquivalent: ""
        )
        fastItem.target = self
        actionSpeedMenu.addItem(fastItem)

        actionSpeedItem.submenu = actionSpeedMenu
        menu.addItem(actionSpeedItem)

        menu.addItem(NSMenuItem.separator())

        // 退出
        let quitItem = NSMenuItem(title: "退出 Nano Pet", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Pet Management

    @objc func addNewPet() {
        let currentPet = AssetPackManager.shared.currentPet
        petManager.addPet(petName: currentPet)
        rebuildMenu()
    }

    @objc func togglePetFromMenu(_ sender: NSMenuItem) {
        guard let petId = sender.representedObject as? UUID,
              let pet = petManager.getPet(by: petId) else { return }
        pet.toggle()
        rebuildMenu()
    }

    @objc func triggerPetAction(_ sender: NSMenuItem) {
        guard let petId = sender.representedObject as? UUID,
              let pet = petManager.getPet(by: petId) else { return }
        pet.triggerRandomAction()
    }

    @objc func removePetFromMenu(_ sender: NSMenuItem) {
        guard let petId = sender.representedObject as? UUID,
              let pet = petManager.getPet(by: petId) else { return }
        petManager.removePet(pet)
        rebuildMenu()
    }

    @objc func showAllPetsAction() {
        petManager.showAllPets()
        rebuildMenu()
    }

    @objc func hideAllPetsAction() {
        petManager.hideAllPets()
        rebuildMenu()
    }

    @objc private func triggerRandomAction() {
        petManager.triggerRandomActionForAll()
    }

    @objc private func openNest() {
        if nestWindow == nil {
            let contentView = NestView()
            nestWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            nestWindow?.title = "Nano Pet"
            nestWindow?.contentView = NSHostingView(rootView: contentView)
            nestWindow?.center()
        }
        nestWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openAIStudio() {
        if aiStudioWindow == nil {
            let contentView = AIStudioView()
            aiStudioWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 900, height: 650),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            aiStudioWindow?.title = "AI 素材工作室"
            aiStudioWindow?.contentView = NSHostingView(rootView: contentView)
            aiStudioWindow?.center()
        }
        aiStudioWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openAssetImport() {
        if assetImportWindow == nil {
            let contentView = AssetImportView()
            assetImportWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            assetImportWindow?.title = "素材包管理"
            assetImportWindow?.contentView = NSHostingView(rootView: contentView)
            assetImportWindow?.center()
        }
        assetImportWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let contentView = SettingsView()
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 550),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = "设置"
            settingsWindow?.contentView = NSHostingView(rootView: contentView)
            settingsWindow?.center()
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - New Menu Handlers

    @objc func toggleJumping() {
        AppSettings.shared.disableJumping.toggle()
        rebuildMenu()
    }

    @objc func toggleHidePets() {
        AppSettings.shared.petsHidden.toggle()
        if AppSettings.shared.petsHidden {
            petManager.hideAllPets()
        } else {
            petManager.showAllPets()
        }
        rebuildMenu()
    }

    @objc func petsGoHome() {
        petManager.removeAllPets()
        rebuildMenu()
    }

    @objc func randomBirth() {
        // Get random pet from validated character list (has actual sprite files)
        let pets = AssetPackManager.shared.getAllCharacters()
        if let randomPet = pets.randomElement() {
            petManager.addPet(petName: randomPet)
        }
        rebuildMenu()
    }

    @objc func toggleAutoSpawn() {
        AppSettings.shared.autoSpawnEnabled.toggle()
        if AppSettings.shared.autoSpawnEnabled {
            startAutoSpawn()
        } else {
            stopAutoSpawn()
        }
        rebuildMenu()
    }

    @objc func showSetIntervalDialog() {
        let alert = NSAlert()
        alert.messageText = "设置自动分身间隔"
        alert.informativeText = "请输入间隔时间（秒）："
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")

        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputField.stringValue = "\(Int(AppSettings.shared.autoSpawnInterval))"
        alert.accessoryView = inputField

        if alert.runModal() == .alertFirstButtonReturn {
            if let seconds = Double(inputField.stringValue), seconds > 0 {
                AppSettings.shared.autoSpawnInterval = seconds
                if AppSettings.shared.autoSpawnEnabled {
                    stopAutoSpawn()
                    startAutoSpawn()
                }
                rebuildMenu()
            }
        }
    }

    private func startAutoSpawn() {
        stopAutoSpawn()
        autoSpawnTimer = Timer.scheduledTimer(withTimeInterval: AppSettings.shared.autoSpawnInterval, repeats: true) { [weak self] _ in
            // 对已有宠物进行分身，而不是随机生成
            self?.petManager.triggerRandomDivide()
        }
    }

    private func stopAutoSpawn() {
        autoSpawnTimer?.invalidate()
        autoSpawnTimer = nil
    }

    // MARK: - Random Replace Handlers

    @objc func toggleRandomReplace() {
        AppSettings.shared.randomReplaceEnabled.toggle()
        if AppSettings.shared.randomReplaceEnabled {
            startRandomReplace()
        } else {
            stopRandomReplace()
        }
        rebuildMenu()
    }

    @objc func showSetRandomReplaceIntervalDialog() {
        let alert = NSAlert()
        alert.messageText = "设置随机替换间隔"
        alert.informativeText = "请输入间隔时间（秒）："
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")

        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputField.stringValue = "\(Int(AppSettings.shared.randomReplaceInterval))"
        alert.accessoryView = inputField

        if alert.runModal() == .alertFirstButtonReturn {
            if let seconds = Double(inputField.stringValue), seconds > 0 {
                AppSettings.shared.randomReplaceInterval = seconds
                if AppSettings.shared.randomReplaceEnabled {
                    stopRandomReplace()
                    startRandomReplace()
                }
                rebuildMenu()
            }
        }
    }

    private func startRandomReplace() {
        stopRandomReplace()
        randomReplaceTimer = Timer.scheduledTimer(withTimeInterval: AppSettings.shared.randomReplaceInterval, repeats: true) { [weak self] _ in
            self?.petManager.replaceAllPetsRandomly()
        }
    }

    private func stopRandomReplace() {
        randomReplaceTimer?.invalidate()
        randomReplaceTimer = nil
    }

    // MARK: - Fullscreen Monitor

    @objc func toggleHideOnFullscreen() {
        AppSettings.shared.hideOnFullscreen.toggle()
        if AppSettings.shared.hideOnFullscreen {
            startFullscreenMonitor()
        } else {
            stopFullscreenMonitor()
            // 如果之前因全屏隐藏了，恢复显示
            if wasHiddenByFullscreen {
                petManager.showAllPets()
                wasHiddenByFullscreen = false
            }
        }
        rebuildMenu()
    }

    private func startFullscreenMonitor() {
        stopFullscreenMonitor()
        fullscreenCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkFullscreenState()
        }
    }

    private func stopFullscreenMonitor() {
        fullscreenCheckTimer?.invalidate()
        fullscreenCheckTimer = nil
    }

    private func checkFullscreenState() {
        let isFullscreen = WindowDetector.shared.isFullscreenActive

        if isFullscreen && !wasHiddenByFullscreen {
            // 进入全屏，隐藏宠物
            print("[FullscreenMonitor] Entering fullscreen - hiding pets")
            petManager.hideAllPets()
            wasHiddenByFullscreen = true
        } else if !isFullscreen && wasHiddenByFullscreen {
            // 退出全屏，恢复宠物
            print("[FullscreenMonitor] Exiting fullscreen - showing pets")
            petManager.showAllPets()
            wasHiddenByFullscreen = false
        }
    }

    // MARK: - Behavior Mode Handlers

    @objc func setBehaviorModeRandom() {
        AppSettings.shared.behaviorMode = .random
        rebuildMenu()
    }

    @objc func setBehaviorModeFocus() {
        AppSettings.shared.behaviorMode = .focus
        // 移动所有宠物到程序坞或屏幕底部
        petManager.moveAllPetsToDockOrBottom()
        rebuildMenu()
    }

    // MARK: - Action Speed Handlers

    @objc func setActionSpeedSlow() {
        AppSettings.shared.actionSpeed = .slow
        rebuildMenu()
    }

    @objc func setActionSpeedMedium() {
        AppSettings.shared.actionSpeed = .medium
        rebuildMenu()
    }

    @objc func setActionSpeedFast() {
        AppSettings.shared.actionSpeed = .fast
        rebuildMenu()
    }
}
