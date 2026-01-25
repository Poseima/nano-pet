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
    private var assetImportWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var autoSpawnTimer: Timer?
    private var randomReplaceTimer: Timer?
    private var fullscreenCheckTimer: Timer?
    private var wasHiddenByFullscreen: Bool = false
    private var statusBarMenu: NSMenu?

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
            // Left-click opens nest window directly
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        rebuildMenu()
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Right-click shows menu
            if let menu = statusBarMenu, let button = statusItem.button {
                menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
            }
        } else {
            // Left-click opens nest window
            openNest()
        }
    }

    func rebuildMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "Nano Pet", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        // Disable/Enable Jumping
        let jumpTitle = AppSettings.shared.disableJumping ? L.menuEnableJumping : L.menuDisableJumping
        let jumpItem = NSMenuItem(title: jumpTitle, action: #selector(toggleJumping), keyEquivalent: "")
        jumpItem.target = self
        menu.addItem(jumpItem)

        // Hide/Show Pets
        let hideTitle = AppSettings.shared.petsHidden ? L.menuShowPets : L.menuHidePets
        let hideItem = NSMenuItem(title: hideTitle, action: #selector(toggleHidePets), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)

        // Hide on Fullscreen
        let fullscreenHideTitle = AppSettings.shared.hideOnFullscreen ? "✓ \(L.menuHideOnFullscreen)" : L.menuHideOnFullscreen
        let fullscreenHideItem = NSMenuItem(title: fullscreenHideTitle, action: #selector(toggleHideOnFullscreen), keyEquivalent: "")
        fullscreenHideItem.target = self
        menu.addItem(fullscreenHideItem)

        // Pets Go Home
        let goHomeItem = NSMenuItem(title: L.menuGoHome, action: #selector(petsGoHome), keyEquivalent: "")
        goHomeItem.target = self
        menu.addItem(goHomeItem)

        // Random Birth
        let randomBirthItem = NSMenuItem(title: L.menuRandomBirth, action: #selector(randomBirth), keyEquivalent: "")
        randomBirthItem.target = self
        menu.addItem(randomBirthItem)

        // Auto Clone submenu
        let autoSpawnItem = NSMenuItem(title: L.menuAutoSpawn, action: nil, keyEquivalent: "")
        let autoSpawnMenu = NSMenu()

        let autoToggleTitle = AppSettings.shared.autoSpawnEnabled ? L.menuStopAutoSpawn : L.menuStartAutoSpawn
        let autoToggleItem = NSMenuItem(title: autoToggleTitle, action: #selector(toggleAutoSpawn), keyEquivalent: "")
        autoToggleItem.target = self
        autoSpawnMenu.addItem(autoToggleItem)

        autoSpawnMenu.addItem(NSMenuItem.separator())

        let interval = AppSettings.shared.autoSpawnInterval
        let intervalText = interval >= 60 ? L.minutes(Int(interval / 60)) : L.seconds(Int(interval))
        let currentIntervalItem = NSMenuItem(title: "\(L.menuCurrentInterval): \(intervalText)", action: nil, keyEquivalent: "")
        currentIntervalItem.isEnabled = false
        autoSpawnMenu.addItem(currentIntervalItem)

        let setIntervalItem = NSMenuItem(title: L.menuSetInterval, action: #selector(showSetIntervalDialog), keyEquivalent: "")
        setIntervalItem.target = self
        autoSpawnMenu.addItem(setIntervalItem)

        autoSpawnItem.submenu = autoSpawnMenu
        menu.addItem(autoSpawnItem)

        // Random Replace submenu
        let randomReplaceItem = NSMenuItem(title: L.menuRandomReplace, action: nil, keyEquivalent: "")
        let randomReplaceMenu = NSMenu()

        let replaceToggleTitle = AppSettings.shared.randomReplaceEnabled ? L.menuStopRandomReplace : L.menuStartRandomReplace
        let replaceToggleItem = NSMenuItem(title: replaceToggleTitle, action: #selector(toggleRandomReplace), keyEquivalent: "")
        replaceToggleItem.target = self
        randomReplaceMenu.addItem(replaceToggleItem)

        randomReplaceMenu.addItem(NSMenuItem.separator())

        let replaceInterval = AppSettings.shared.randomReplaceInterval
        let replaceIntervalText = replaceInterval >= 60 ? L.minutes(Int(replaceInterval / 60)) : L.seconds(Int(replaceInterval))
        let currentReplaceIntervalItem = NSMenuItem(title: "\(L.menuCurrentInterval): \(replaceIntervalText)", action: nil, keyEquivalent: "")
        currentReplaceIntervalItem.isEnabled = false
        randomReplaceMenu.addItem(currentReplaceIntervalItem)

        let setReplaceIntervalItem = NSMenuItem(title: L.menuSetInterval, action: #selector(showSetRandomReplaceIntervalDialog), keyEquivalent: "")
        setReplaceIntervalItem.target = self
        randomReplaceMenu.addItem(setReplaceIntervalItem)

        randomReplaceItem.submenu = randomReplaceMenu
        menu.addItem(randomReplaceItem)

        menu.addItem(NSMenuItem.separator())

        // Behavior Mode submenu
        let behaviorModeItem = NSMenuItem(title: L.menuBehaviorMode, action: nil, keyEquivalent: "")
        let behaviorModeMenu = NSMenu()

        let randomModeItem = NSMenuItem(
            title: AppSettings.shared.behaviorMode == .random ? "✓ \(L.behaviorRandom)" : L.behaviorRandom,
            action: #selector(setBehaviorModeRandom),
            keyEquivalent: ""
        )
        randomModeItem.target = self
        behaviorModeMenu.addItem(randomModeItem)

        let focusModeItem = NSMenuItem(
            title: AppSettings.shared.behaviorMode == .focus ? "✓ \(L.behaviorFocus)" : L.behaviorFocus,
            action: #selector(setBehaviorModeFocus),
            keyEquivalent: ""
        )
        focusModeItem.target = self
        behaviorModeMenu.addItem(focusModeItem)

        behaviorModeItem.submenu = behaviorModeMenu
        menu.addItem(behaviorModeItem)

        // Action Speed submenu
        let actionSpeedItem = NSMenuItem(title: L.menuActionSpeed, action: nil, keyEquivalent: "")
        let actionSpeedMenu = NSMenu()

        let slowItem = NSMenuItem(
            title: AppSettings.shared.actionSpeed == .slow ? "✓ \(L.speedSlow)" : L.speedSlow,
            action: #selector(setActionSpeedSlow),
            keyEquivalent: ""
        )
        slowItem.target = self
        actionSpeedMenu.addItem(slowItem)

        let mediumItem = NSMenuItem(
            title: AppSettings.shared.actionSpeed == .medium ? "✓ \(L.speedMedium)" : L.speedMedium,
            action: #selector(setActionSpeedMedium),
            keyEquivalent: ""
        )
        mediumItem.target = self
        actionSpeedMenu.addItem(mediumItem)

        let fastItem = NSMenuItem(
            title: AppSettings.shared.actionSpeed == .fast ? "✓ \(L.speedFast)" : L.speedFast,
            action: #selector(setActionSpeedFast),
            keyEquivalent: ""
        )
        fastItem.target = self
        actionSpeedMenu.addItem(fastItem)

        actionSpeedItem.submenu = actionSpeedMenu
        menu.addItem(actionSpeedItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: L.menuQuit, action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        statusBarMenu = menu
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
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            nestWindow?.title = "Nano Pet"
            nestWindow?.contentView = NSHostingView(rootView: contentView)
            nestWindow?.center()
            nestWindow?.isReleasedWhenClosed = false
        }
        nestWindow?.makeKeyAndOrderFront(nil)
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
            assetImportWindow?.title = L.assetImportTitle
            assetImportWindow?.contentView = NSHostingView(rootView: contentView)
            assetImportWindow?.center()
            assetImportWindow?.isReleasedWhenClosed = false
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
            settingsWindow?.title = L.settingsTitle
            settingsWindow?.contentView = NSHostingView(rootView: contentView)
            settingsWindow?.center()
            settingsWindow?.isReleasedWhenClosed = false
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
        applyAutoSpawnState()
    }

    /// 从设置页面调用：应用当前自动分身状态（不toggle）
    @objc func applyAutoSpawnState() {
        if AppSettings.shared.autoSpawnEnabled {
            startAutoSpawn()
        } else {
            stopAutoSpawn()
        }
        rebuildMenu()
    }

    @objc func showSetIntervalDialog() {
        let alert = NSAlert()
        alert.messageText = L.dialogSetAutoCloneInterval
        alert.informativeText = L.dialogEnterIntervalSeconds
        alert.alertStyle = .informational
        alert.addButton(withTitle: L.commonOK)
        alert.addButton(withTitle: L.commonCancel)

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

    /// 从设置页面调用：重启自动分身定时器
    @objc func restartAutoSpawn() {
        if AppSettings.shared.autoSpawnEnabled {
            stopAutoSpawn()
            startAutoSpawn()
        }
        rebuildMenu()
    }

    // MARK: - Random Replace Handlers

    @objc func toggleRandomReplace() {
        AppSettings.shared.randomReplaceEnabled.toggle()
        applyRandomReplaceState()
    }

    /// 从设置页面调用：应用当前随机替换状态（不toggle）
    @objc func applyRandomReplaceState() {
        if AppSettings.shared.randomReplaceEnabled {
            startRandomReplace()
        } else {
            stopRandomReplace()
        }
        rebuildMenu()
    }

    @objc func showSetRandomReplaceIntervalDialog() {
        let alert = NSAlert()
        alert.messageText = L.dialogSetRandomReplaceInterval
        alert.informativeText = L.dialogEnterIntervalSeconds
        alert.alertStyle = .informational
        alert.addButton(withTitle: L.commonOK)
        alert.addButton(withTitle: L.commonCancel)

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

    /// 从设置页面调用：重启随机替换定时器
    @objc func restartRandomReplace() {
        if AppSettings.shared.randomReplaceEnabled {
            stopRandomReplace()
            startRandomReplace()
        }
        rebuildMenu()
    }

    // MARK: - Fullscreen Monitor

    @objc func toggleHideOnFullscreen() {
        AppSettings.shared.hideOnFullscreen.toggle()
        applyHideOnFullscreenState()
    }

    /// 从设置页面调用：应用当前全屏隐藏状态（不toggle）
    @objc func applyHideOnFullscreenState() {
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
