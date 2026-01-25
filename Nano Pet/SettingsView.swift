//
//  SettingsView.swift
//  Nano Pet
//
//  设置面板 - 全局设置和偏好
//

import SwiftUI
import ServiceManagement

// MARK: - Behavior Mode Enum

enum BehaviorMode: String, CaseIterable {
    case random = "random"
    case focus = "focus"

    var displayName: String {
        switch self {
        case .random: return L.behaviorRandom
        case .focus: return L.behaviorFocus
        }
    }
}

// MARK: - Action Speed Enum

enum ActionSpeed: String, CaseIterable {
    case slow = "slow"      // 6s = 360 ticks
    case medium = "medium"  // 4s = 240 ticks
    case fast = "fast"      // 3s = 180 ticks - default

    var displayName: String {
        switch self {
        case .slow: return L.speedSlow
        case .medium: return L.speedMedium
        case .fast: return L.speedFast
        }
    }
}

// MARK: - App Settings

@Observable
class AppSettings {
    static let shared = AppSettings()

    // 语言设置
    var language: AppLanguage {
        didSet { save() }
    }

    // 启动设置
    var launchAtLogin: Bool {
        didSet {
            save()
            updateLaunchAtLogin()
        }
    }

    // 显示设置
    var hideOnFullscreen: Bool {
        didSet { save() }
    }
    var allowPetsInWindows: Bool {
        didSet { save() }
    }

    // 行为设置
    var disableJumping: Bool {
        didSet { save() }
    }
    var behaviorMode: BehaviorMode {
        didSet { save() }
    }
    var actionSpeed: ActionSpeed {
        didSet { save() }
    }

    // 自动功能设置
    var autoSpawnEnabled: Bool {
        didSet { save() }
    }
    var autoSpawnInterval: Double {
        didSet { save() }
    }
    var randomReplaceEnabled: Bool {
        didSet { save() }
    }
    var randomReplaceInterval: Double {
        didSet { save() }
    }

    // 声音设置
    var enableSounds: Bool {
        didSet {
            save()
            if !enableSounds {
                SoundManager.shared.stopAllSounds()
            }
        }
    }
    var soundVolume: Double {
        didSet {
            save()
            SoundManager.shared.updateVolume()
        }
    }

    // 内部状态（不在设置页面显示）
    var petsHidden: Bool {
        didSet { save() }
    }

    // 辅助属性：获取 idle duration
    var idleDurationTicks: UInt64 {
        switch actionSpeed {
        case .slow: return 360    // 6 秒
        case .medium: return 240  // 4 秒
        case .fast: return 180    // 3 秒
        }
    }

    private let defaults = UserDefaults.standard

    init() {
        // 语言设置
        self.language = AppLanguage(rawValue: defaults.string(forKey: "language") ?? "en") ?? .english

        // 启动设置
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")

        // 显示设置
        self.hideOnFullscreen = defaults.bool(forKey: "hideOnFullscreen")
        self.allowPetsInWindows = defaults.object(forKey: "allowPetsInWindows") == nil ? true : defaults.bool(forKey: "allowPetsInWindows")

        // 行为设置
        self.disableJumping = defaults.bool(forKey: "disableJumping")
        self.behaviorMode = BehaviorMode(rawValue: defaults.string(forKey: "behaviorMode") ?? "random") ?? .random
        self.actionSpeed = ActionSpeed(rawValue: defaults.string(forKey: "actionSpeed") ?? "fast") ?? .fast

        // 自动功能设置
        self.autoSpawnEnabled = defaults.bool(forKey: "autoSpawnEnabled")
        self.autoSpawnInterval = defaults.double(forKey: "autoSpawnInterval") == 0 ? 30.0 : defaults.double(forKey: "autoSpawnInterval")
        self.randomReplaceEnabled = defaults.bool(forKey: "randomReplaceEnabled")
        self.randomReplaceInterval = defaults.double(forKey: "randomReplaceInterval") == 0 ? 60.0 : defaults.double(forKey: "randomReplaceInterval")

        // 声音设置
        self.enableSounds = defaults.bool(forKey: "enableSounds")
        self.soundVolume = defaults.double(forKey: "soundVolume") == 0 ? 0.5 : defaults.double(forKey: "soundVolume")

        // 内部状态
        self.petsHidden = defaults.bool(forKey: "petsHidden")
    }

    private func save() {
        // 语言设置
        defaults.set(language.rawValue, forKey: "language")

        // 启动设置
        defaults.set(launchAtLogin, forKey: "launchAtLogin")

        // 显示设置
        defaults.set(hideOnFullscreen, forKey: "hideOnFullscreen")
        defaults.set(allowPetsInWindows, forKey: "allowPetsInWindows")

        // 行为设置
        defaults.set(disableJumping, forKey: "disableJumping")
        defaults.set(behaviorMode.rawValue, forKey: "behaviorMode")
        defaults.set(actionSpeed.rawValue, forKey: "actionSpeed")

        // 自动功能设置
        defaults.set(autoSpawnEnabled, forKey: "autoSpawnEnabled")
        defaults.set(autoSpawnInterval, forKey: "autoSpawnInterval")
        defaults.set(randomReplaceEnabled, forKey: "randomReplaceEnabled")
        defaults.set(randomReplaceInterval, forKey: "randomReplaceInterval")

        // 声音设置
        defaults.set(enableSounds, forKey: "enableSounds")
        defaults.set(soundVolume, forKey: "soundVolume")

        // 内部状态
        defaults.set(petsHidden, forKey: "petsHidden")
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            titleBar

            ScrollView {
                VStack(spacing: 24) {
                    languageSection
                    launchSection
                    displaySection
                    behaviorSection
                    autoFunctionSection
                    aboutSection
                }
                .padding(24)
            }
        }
        .background(Color(hex: "#F5F5F7"))
        .frame(minWidth: 450, minHeight: 550)
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .foregroundColor(Color(hex: "#007AFF"))
            Text(L.settingsTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "#1D1D1F"))

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
    }

    // MARK: - Language Section

    private var languageSection: some View {
        SettingsSection(title: L.settingsLanguage, icon: "globe") {
            SettingsPicker(
                title: L.settingsLanguage,
                selection: Binding(
                    get: { settings.language },
                    set: { newValue in
                        settings.language = newValue
                        AppDelegate.shared?.rebuildMenu()
                    }
                ),
                options: AppLanguage.allCases
            ) { lang in
                lang.displayName
            }
        }
    }

    // MARK: - Launch Section

    private var launchSection: some View {
        SettingsSection(title: L.settingsLaunch, icon: "power") {
            SettingsToggle(
                title: L.settingsLaunchAtLogin,
                subtitle: L.settingsLaunchAtLoginSubtitle,
                isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.launchAtLogin = $0 }
                )
            )
        }
    }

    // MARK: - Display Section

    private var displaySection: some View {
        SettingsSection(title: L.settingsDisplay, icon: "display") {
            VStack(spacing: 16) {
                SettingsToggle(
                    title: L.settingsHideOnFullscreen,
                    subtitle: L.settingsHideOnFullscreenSubtitle,
                    isOn: Binding(
                        get: { settings.hideOnFullscreen },
                        set: { newValue in
                            settings.hideOnFullscreen = newValue
                            AppDelegate.shared?.applyHideOnFullscreenState()
                        }
                    )
                )

                Divider()

                SettingsToggle(
                    title: L.settingsAllowInWindows,
                    subtitle: L.settingsAllowInWindowsSubtitle,
                    isOn: Binding(
                        get: { settings.allowPetsInWindows },
                        set: { settings.allowPetsInWindows = $0 }
                    )
                )
            }
        }
    }

    // MARK: - Behavior Section

    private var behaviorSection: some View {
        SettingsSection(title: L.settingsBehavior, icon: "sparkles") {
            VStack(spacing: 16) {
                SettingsToggle(
                    title: L.settingsDisableJumping,
                    subtitle: L.settingsDisableJumpingSubtitle,
                    isOn: Binding(
                        get: { settings.disableJumping },
                        set: { settings.disableJumping = $0 }
                    )
                )

                Divider()

                SettingsPicker(
                    title: L.settingsBehaviorMode,
                    selection: Binding(
                        get: { settings.behaviorMode },
                        set: { newValue in
                            settings.behaviorMode = newValue
                            if newValue == .focus {
                                PetManager.shared.moveAllPetsToDockOrBottom()
                            }
                        }
                    ),
                    options: BehaviorMode.allCases
                ) { mode in
                    mode.displayName
                }

                Divider()

                SettingsPicker(
                    title: L.settingsActionSpeed,
                    selection: Binding(
                        get: { settings.actionSpeed },
                        set: { settings.actionSpeed = $0 }
                    ),
                    options: ActionSpeed.allCases
                ) { speed in
                    speed.displayName
                }
            }
        }
    }

    // MARK: - Auto Function Section

    private var autoFunctionSection: some View {
        SettingsSection(title: L.settingsAutoFeatures, icon: "arrow.triangle.2.circlepath") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    SettingsToggle(
                        title: L.settingsAutoClone,
                        subtitle: L.settingsAutoCloneSubtitle,
                        isOn: Binding(
                            get: { settings.autoSpawnEnabled },
                            set: { newValue in
                                settings.autoSpawnEnabled = newValue
                                AppDelegate.shared?.applyAutoSpawnState()
                            }
                        )
                    )

                    if settings.autoSpawnEnabled {
                        SettingsIntervalInput(
                            label: L.settingsInterval,
                            value: Binding(
                                get: { settings.autoSpawnInterval },
                                set: { newValue in
                                    settings.autoSpawnInterval = newValue
                                    if settings.autoSpawnEnabled {
                                        AppDelegate.shared?.restartAutoSpawn()
                                    }
                                }
                            ),
                            unit: L.settingsSeconds
                        )
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    SettingsToggle(
                        title: L.settingsRandomReplace,
                        subtitle: L.settingsRandomReplaceSubtitle,
                        isOn: Binding(
                            get: { settings.randomReplaceEnabled },
                            set: { newValue in
                                settings.randomReplaceEnabled = newValue
                                AppDelegate.shared?.applyRandomReplaceState()
                            }
                        )
                    )

                    if settings.randomReplaceEnabled {
                        SettingsIntervalInput(
                            label: L.settingsInterval,
                            value: Binding(
                                get: { settings.randomReplaceInterval },
                                set: { newValue in
                                    settings.randomReplaceInterval = newValue
                                    if settings.randomReplaceEnabled {
                                        AppDelegate.shared?.restartRandomReplace()
                                    }
                                }
                            ),
                            unit: L.settingsSeconds
                        )
                    }
                }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        SettingsSection(title: L.settingsAbout, icon: "info.circle") {
            VStack(spacing: 12) {
                HStack {
                    Text(L.settingsVersion)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#86868B"))
                    Spacer()
                    Text("1.0.0")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#1D1D1F"))
                }

                Divider()

                HStack {
                    Spacer()
                    Text("Nano Pet")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#AEAEB2"))
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Helper Views

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "#007AFF"))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#1D1D1F"))
            }

            VStack(spacing: 0) {
                content
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

struct SettingsSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let valueLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#1D1D1F"))
                Spacer()
                Text(valueLabel)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#86868B"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#F5F5F7"))
                    .cornerRadius(4)
            }

            Slider(value: $value, in: range)
                .tint(Color(hex: "#007AFF"))
        }
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#1D1D1F"))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#AEAEB2"))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(Color(hex: "#007AFF"))
        }
    }
}

struct SettingsPicker<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    let labelForOption: (T) -> String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#1D1D1F"))

            Spacer()

            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(labelForOption(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(Color(hex: "#007AFF"))
        }
    }
}

struct SettingsIntervalInput: View {
    let label: String
    @Binding var value: Double
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#86868B"))

            Spacer()

            HStack(spacing: 8) {
                TextField("", value: $value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)

                Text(unit)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#86868B"))
            }
        }
        .padding(.leading, 16)
    }
}

#Preview {
    SettingsView()
}
