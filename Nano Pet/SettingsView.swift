//
//  SettingsView.swift
//  Nano Pet
//
//  设置面板 - 全局设置和偏好
//

import SwiftUI
import ServiceManagement

// MARK: - Behavior Mode Enum

enum BehaviorMode: String {
    case random = "random"    // 随机行为（当前默认）
    case focus = "focus"      // 专注模式
}

// MARK: - Action Speed Enum

enum ActionSpeed: String {
    case slow = "slow"        // 慢 (6秒 = 360 ticks)
    case medium = "medium"    // 中等 (4秒 = 240 ticks)
    case fast = "fast"        // 快 (3秒 = 180 ticks) - 当前默认
}

// MARK: - App Settings

@Observable
class AppSettings {
    static let shared = AppSettings()

    // 显示设置
    var petSize: Double {
        didSet { save() }
    }
    var animationSpeed: Double {
        didSet { save() }
    }
    var alwaysOnTop: Bool {
        didSet { save() }
    }

    // 行为设置
    var activityLevel: Double {
        didSet { save() }
    }
    var enableWindowInteraction: Bool {
        didSet { save() }
    }
    var allowPetsInWindows: Bool {
        didSet { save() }
    }

    // 声音设置
    var enableSounds: Bool {
        didSet {
            save()
            // Stop all sounds if disabled
            if !enableSounds {
                SoundManager.shared.stopAllSounds()
            }
        }
    }
    var soundVolume: Double {
        didSet {
            save()
            // Update volume in sound manager
            SoundManager.shared.updateVolume()
        }
    }

    // API 设置
    var openRouterAPIKey: String {
        didSet { save() }
    }

    // 启动设置
    var launchAtLogin: Bool {
        didSet {
            save()
            updateLaunchAtLogin()
        }
    }

    // 新增：菜单控制设置
    var disableJumping: Bool {
        didSet { save() }
    }
    var autoSpawnEnabled: Bool {
        didSet { save() }
    }
    var autoSpawnInterval: Double {
        didSet { save() }
    }
    // 随机替换设置
    var randomReplaceEnabled: Bool {
        didSet { save() }
    }
    var randomReplaceInterval: Double {
        didSet { save() }
    }
    var petsHidden: Bool {
        didSet { save() }
    }
    var hideOnFullscreen: Bool {
        didSet { save() }
    }

    // 行为模式和动作频率
    var behaviorMode: BehaviorMode {
        didSet { save() }
    }
    var actionSpeed: ActionSpeed {
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
        // 加载保存的设置或使用默认值
        self.petSize = defaults.double(forKey: "petSize") == 0 ? 1.0 : defaults.double(forKey: "petSize")
        self.animationSpeed = defaults.double(forKey: "animationSpeed") == 0 ? 1.0 : defaults.double(forKey: "animationSpeed")
        self.alwaysOnTop = defaults.bool(forKey: "alwaysOnTop")
        self.activityLevel = defaults.double(forKey: "activityLevel") == 0 ? 0.5 : defaults.double(forKey: "activityLevel")
        self.enableWindowInteraction = defaults.object(forKey: "enableWindowInteraction") == nil ? true : defaults.bool(forKey: "enableWindowInteraction")
        self.allowPetsInWindows = defaults.object(forKey: "allowPetsInWindows") == nil ? true : defaults.bool(forKey: "allowPetsInWindows")
        self.enableSounds = defaults.bool(forKey: "enableSounds")
        self.soundVolume = defaults.double(forKey: "soundVolume") == 0 ? 0.5 : defaults.double(forKey: "soundVolume")
        self.openRouterAPIKey = defaults.string(forKey: "openRouterAPIKey") ?? ""
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")

        // 新增设置
        self.disableJumping = defaults.bool(forKey: "disableJumping")
        self.autoSpawnEnabled = defaults.bool(forKey: "autoSpawnEnabled")
        self.autoSpawnInterval = defaults.double(forKey: "autoSpawnInterval") == 0 ? 30.0 : defaults.double(forKey: "autoSpawnInterval")
        self.randomReplaceEnabled = defaults.bool(forKey: "randomReplaceEnabled")
        self.randomReplaceInterval = defaults.double(forKey: "randomReplaceInterval") == 0 ? 60.0 : defaults.double(forKey: "randomReplaceInterval")
        self.petsHidden = defaults.bool(forKey: "petsHidden")
        self.hideOnFullscreen = defaults.bool(forKey: "hideOnFullscreen")

        // 行为模式和动作频率
        self.behaviorMode = BehaviorMode(rawValue: defaults.string(forKey: "behaviorMode") ?? "random") ?? .random
        self.actionSpeed = ActionSpeed(rawValue: defaults.string(forKey: "actionSpeed") ?? "fast") ?? .fast
    }

    private func save() {
        defaults.set(petSize, forKey: "petSize")
        defaults.set(animationSpeed, forKey: "animationSpeed")
        defaults.set(alwaysOnTop, forKey: "alwaysOnTop")
        defaults.set(activityLevel, forKey: "activityLevel")
        defaults.set(enableWindowInteraction, forKey: "enableWindowInteraction")
        defaults.set(allowPetsInWindows, forKey: "allowPetsInWindows")
        defaults.set(enableSounds, forKey: "enableSounds")
        defaults.set(soundVolume, forKey: "soundVolume")
        defaults.set(openRouterAPIKey, forKey: "openRouterAPIKey")
        defaults.set(launchAtLogin, forKey: "launchAtLogin")

        // 新增设置
        defaults.set(disableJumping, forKey: "disableJumping")
        defaults.set(autoSpawnEnabled, forKey: "autoSpawnEnabled")
        defaults.set(autoSpawnInterval, forKey: "autoSpawnInterval")
        defaults.set(randomReplaceEnabled, forKey: "randomReplaceEnabled")
        defaults.set(randomReplaceInterval, forKey: "randomReplaceInterval")
        defaults.set(petsHidden, forKey: "petsHidden")
        defaults.set(hideOnFullscreen, forKey: "hideOnFullscreen")

        // 行为模式和动作频率
        defaults.set(behaviorMode.rawValue, forKey: "behaviorMode")
        defaults.set(actionSpeed.rawValue, forKey: "actionSpeed")
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
    @State private var showingAPIKeyAlert = false
    @State private var apiKeyValidationStatus: APIKeyStatus = .unknown

    enum APIKeyStatus {
        case unknown, validating, valid, invalid
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar

            ScrollView {
                VStack(spacing: 24) {
                    // 显示设置
                    displaySection

                    // 行为设置
                    behaviorSection

                    // 声音设置
                    soundSection

                    // API 设置
                    apiSection

                    // 关于
                    aboutSection
                }
                .padding(24)
            }
        }
        .background(Color(hex: "#FFF8F0"))
        .frame(minWidth: 450, minHeight: 500)
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .foregroundColor(Color(hex: "#FFB5A7"))
            Text("设置")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
    }

    // MARK: - Display Section

    private var displaySection: some View {
        SettingsSection(title: "显示", icon: "display") {
            VStack(spacing: 16) {
                // 宠物大小
                SettingsSlider(
                    title: "宠物大小",
                    value: $settings.petSize,
                    range: 0.5...2.0,
                    valueLabel: "\(Int(settings.petSize * 100))%"
                )

                // 动画速度
                SettingsSlider(
                    title: "动画速度",
                    value: $settings.animationSpeed,
                    range: 0.5...2.0,
                    valueLabel: speedLabel
                )

                Divider()

                // 开机自启动
                SettingsToggle(
                    title: "开机自启动",
                    subtitle: "登录时自动启动 Nano Pet",
                    isOn: $settings.launchAtLogin
                )

                // 始终置顶
                SettingsToggle(
                    title: "始终置顶",
                    subtitle: "宠物始终显示在其他窗口上方",
                    isOn: $settings.alwaysOnTop
                )
            }
        }
    }

    private var speedLabel: String {
        if settings.animationSpeed < 0.7 {
            return "慢速"
        } else if settings.animationSpeed > 1.3 {
            return "快速"
        } else {
            return "正常"
        }
    }

    // MARK: - Behavior Section

    private var behaviorSection: some View {
        SettingsSection(title: "行为", icon: "sparkles") {
            VStack(spacing: 16) {
                // 活跃程度
                SettingsSlider(
                    title: "活跃程度",
                    value: $settings.activityLevel,
                    range: 0.0...1.0,
                    valueLabel: activityLabel
                )

                Divider()

                // 环境交互
                SettingsToggle(
                    title: "环境交互",
                    subtitle: "允许宠物与窗口边缘互动",
                    isOn: $settings.enableWindowInteraction
                )

                // 窗口内显示
                SettingsToggle(
                    title: "窗口内显示",
                    subtitle: "允许宠物在其他窗口区域内显示",
                    isOn: $settings.allowPetsInWindows
                )
            }
        }
    }

    private var activityLabel: String {
        if settings.activityLevel < 0.3 {
            return "安静"
        } else if settings.activityLevel > 0.7 {
            return "活泼"
        } else {
            return "中等"
        }
    }

    // MARK: - Sound Section

    private var soundSection: some View {
        SettingsSection(title: "声音", icon: "speaker.wave.2") {
            VStack(spacing: 16) {
                // 音效开关
                SettingsToggle(
                    title: "音效",
                    subtitle: "播放宠物互动音效",
                    isOn: $settings.enableSounds
                )

                if settings.enableSounds {
                    // 音量
                    SettingsSlider(
                        title: "音量",
                        value: $settings.soundVolume,
                        range: 0.0...1.0,
                        valueLabel: "\(Int(settings.soundVolume * 100))%"
                    )
                }
            }
        }
    }

    // MARK: - API Section

    private var apiSection: some View {
        SettingsSection(title: "API", icon: "key") {
            VStack(alignment: .leading, spacing: 12) {
                Text("OpenRouter API Key")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#2D3436"))

                HStack {
                    SecureField("输入你的 API Key...", text: $settings.openRouterAPIKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, design: .rounded))

                    Button(action: validateAPIKey) {
                        switch apiKeyValidationStatus {
                        case .unknown:
                            Text("验证")
                        case .validating:
                            ProgressView()
                                .scaleEffect(0.7)
                        case .valid:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        case .invalid:
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#F8F9FA"))
                    .cornerRadius(6)
                    .disabled(settings.openRouterAPIKey.isEmpty)
                }

                Text("用于 AI 素材工作室生成宠物素材")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(Color(hex: "#B2BEC3"))

                Link("获取 API Key", destination: URL(string: "https://openrouter.ai/keys")!)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Color(hex: "#FFB5A7"))
            }
        }
    }

    private func validateAPIKey() {
        apiKeyValidationStatus = .validating
        // 简单验证：检查 key 格式
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                if settings.openRouterAPIKey.hasPrefix("sk-") && settings.openRouterAPIKey.count > 20 {
                    apiKeyValidationStatus = .valid
                } else {
                    apiKeyValidationStatus = .invalid
                }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        SettingsSection(title: "关于", icon: "info.circle") {
            VStack(spacing: 12) {
                HStack {
                    Text("版本")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(Color(hex: "#636E72"))
                    Spacer()
                    Text("1.0.0")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(Color(hex: "#2D3436"))
                }

                Divider()

                HStack {
                    Spacer()
                    Text("Nano Pet")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color(hex: "#B2BEC3"))
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
                    .foregroundColor(Color(hex: "#FFB5A7"))
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#2D3436"))
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
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Color(hex: "#2D3436"))
                Spacer()
                Text(valueLabel)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Color(hex: "#636E72"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#F8F9FA"))
                    .cornerRadius(4)
            }

            Slider(value: $value, in: range)
                .tint(Color(hex: "#FFB5A7"))
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
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Color(hex: "#2D3436"))
                Text(subtitle)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(Color(hex: "#B2BEC3"))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(Color(hex: "#FFB5A7"))
        }
    }
}

#Preview {
    SettingsView()
}
