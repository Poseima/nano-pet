//
//  Localization.swift
//  Nano Pet
//
//  App-internal localization management
//

import Foundation

// MARK: - App Language

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case chinese = "zh"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}

// MARK: - Localization Strings

struct L {
    static var current: AppLanguage { AppSettings.shared.language }

    // MARK: - Menu Bar

    static var menuDisableJumping: String {
        current == .english ? "Disable Jumping" : "禁用跳跃"
    }

    static var menuEnableJumping: String {
        current == .english ? "Enable Jumping" : "启用跳跃"
    }

    static var menuHidePets: String {
        current == .english ? "Hide Pets" : "隐藏宠物"
    }

    static var menuShowPets: String {
        current == .english ? "Show Pets" : "显示宠物"
    }

    static var menuHideOnFullscreen: String {
        current == .english ? "Hide on Fullscreen" : "全屏隐藏"
    }

    static var menuGoHome: String {
        current == .english ? "Pets Go Home" : "宠物回家"
    }

    static var menuRandomBirth: String {
        current == .english ? "Random Birth" : "随机诞生"
    }

    static var menuAutoSpawn: String {
        current == .english ? "Auto Clone" : "自动分身"
    }

    static var menuStartAutoSpawn: String {
        current == .english ? "Start Auto Clone" : "开始自动分身"
    }

    static var menuStopAutoSpawn: String {
        current == .english ? "Stop Auto Clone" : "停止自动分身"
    }

    static var menuCurrentInterval: String {
        current == .english ? "Current Interval" : "当前间隔"
    }

    static var menuSetInterval: String {
        current == .english ? "Set Interval..." : "设置间隔..."
    }

    static var menuRandomReplace: String {
        current == .english ? "Random Replace" : "随机替换"
    }

    static var menuStartRandomReplace: String {
        current == .english ? "Start Random Replace" : "开始随机替换"
    }

    static var menuStopRandomReplace: String {
        current == .english ? "Stop Random Replace" : "停止随机替换"
    }

    static var menuBehaviorMode: String {
        current == .english ? "Behavior Mode" : "行为模式"
    }

    static var menuActionSpeed: String {
        current == .english ? "Action Speed" : "动作频率"
    }

    static var menuQuit: String {
        current == .english ? "Quit Nano Pet" : "退出 Nano Pet"
    }

    // MARK: - Behavior Mode

    static var behaviorRandom: String {
        current == .english ? "Random" : "随机行为"
    }

    static var behaviorFocus: String {
        current == .english ? "Focus Mode" : "专注模式"
    }

    // MARK: - Action Speed

    static var speedSlow: String {
        current == .english ? "Slow" : "慢"
    }

    static var speedMedium: String {
        current == .english ? "Medium" : "中等"
    }

    static var speedFast: String {
        current == .english ? "Fast" : "快"
    }

    // MARK: - Settings

    static var settingsTitle: String {
        current == .english ? "Settings" : "设置"
    }

    static var settingsLanguage: String {
        current == .english ? "Language" : "语言"
    }

    static var settingsLaunch: String {
        current == .english ? "Launch" : "启动"
    }

    static var settingsDisplay: String {
        current == .english ? "Display" : "显示"
    }

    static var settingsBehavior: String {
        current == .english ? "Behavior" : "行为"
    }

    static var settingsAutoFeatures: String {
        current == .english ? "Auto Features" : "自动功能"
    }

    static var settingsAbout: String {
        current == .english ? "About" : "关于"
    }

    static var settingsLaunchAtLogin: String {
        current == .english ? "Launch at Login" : "开机自启动"
    }

    static var settingsLaunchAtLoginSubtitle: String {
        current == .english ? "Automatically start Nano Pet at login" : "登录时自动启动 Nano Pet"
    }

    static var settingsHideOnFullscreen: String {
        current == .english ? "Hide on Fullscreen" : "全屏隐藏"
    }

    static var settingsHideOnFullscreenSubtitle: String {
        current == .english ? "Automatically hide pets in fullscreen apps" : "全屏应用时自动隐藏宠物"
    }

    static var settingsAllowInWindows: String {
        current == .english ? "Show in Windows" : "窗口内显示"
    }

    static var settingsAllowInWindowsSubtitle: String {
        current == .english ? "Allow pets to appear on other windows" : "允许宠物在其他窗口上显示"
    }

    static var settingsDisableJumping: String {
        current == .english ? "Disable Jumping" : "禁用跳跃"
    }

    static var settingsDisableJumpingSubtitle: String {
        current == .english ? "Pets will not jump" : "宠物不会跳跃"
    }

    static var settingsBehaviorMode: String {
        current == .english ? "Behavior Mode" : "行为模式"
    }

    static var settingsActionSpeed: String {
        current == .english ? "Action Speed" : "动作频率"
    }

    static var settingsAutoClone: String {
        current == .english ? "Auto Clone" : "自动分身"
    }

    static var settingsAutoCloneSubtitle: String {
        current == .english ? "Automatically add new pets periodically" : "定时自动添加新宠物"
    }

    static var settingsRandomReplace: String {
        current == .english ? "Random Replace" : "随机替换"
    }

    static var settingsRandomReplaceSubtitle: String {
        current == .english ? "Randomly change pet characters periodically" : "定时随机更换宠物角色"
    }

    static var settingsInterval: String {
        current == .english ? "Interval" : "间隔"
    }

    static var settingsSeconds: String {
        current == .english ? "seconds" : "秒"
    }

    static var settingsVersion: String {
        current == .english ? "Version" : "版本"
    }

    // MARK: - Common

    static var commonOK: String {
        current == .english ? "OK" : "确定"
    }

    static var commonCancel: String {
        current == .english ? "Cancel" : "取消"
    }

    static var commonDelete: String {
        current == .english ? "Delete" : "删除"
    }

    static var commonUse: String {
        current == .english ? "Use" : "使用"
    }

    static var commonInUse: String {
        current == .english ? "In Use" : "使用中"
    }

    // MARK: - Dialogs

    static var dialogSetAutoCloneInterval: String {
        current == .english ? "Set Auto Clone Interval" : "设置自动分身间隔"
    }

    static var dialogEnterIntervalSeconds: String {
        current == .english ? "Enter interval (seconds):" : "请输入间隔时间（秒）："
    }

    static var dialogSetRandomReplaceInterval: String {
        current == .english ? "Set Random Replace Interval" : "设置随机替换间隔"
    }

    // MARK: - Time Units

    static func minutes(_ count: Int) -> String {
        current == .english ? "\(count) min" : "\(count)分钟"
    }

    static func seconds(_ count: Int) -> String {
        current == .english ? "\(count)s" : "\(count)秒"
    }

    // MARK: - Asset Import View

    static var assetImportTitle: String {
        current == .english ? "Asset Manager" : "素材包管理"
    }

    static var assetImportButton: String {
        current == .english ? "Import Assets" : "导入素材"
    }

    static var assetImportNoCharacters: String {
        current == .english ? "No characters yet" : "还没有角色"
    }

    static var assetImportClickToImport: String {
        current == .english ? "Click \"Import Assets\" button above to import characters" : "点击上方\"导入素材\"按钮导入角色"
    }

    static var assetImportedCharacters: String {
        current == .english ? "Imported Characters" : "已导入的角色"
    }

    static var assetImportedPacks: String {
        current == .english ? "Imported Asset Packs" : "导入的素材包"
    }

    static var assetImportCount: String {
        current == .english ? "items" : "个"
    }

    static var assetAnimations: String {
        current == .english ? "animations" : "个动画"
    }

    static var assetImportError: String {
        current == .english ? "Import Error" : "导入错误"
    }

    static var assetUnknownError: String {
        current == .english ? "Unknown error" : "未知错误"
    }

    static var assetConfirmDelete: String {
        current == .english ? "Confirm Delete" : "确认删除"
    }

    static func assetDeletePackConfirm(_ name: String) -> String {
        current == .english
            ? "Are you sure you want to delete asset pack \"\(name)\"? This action cannot be undone."
            : "确定要删除素材包 \"\(name)\" 吗？此操作不可撤销。"
    }

    static var assetConfirmDeleteCharacter: String {
        current == .english ? "Confirm Delete Character" : "确认删除角色"
    }

    static func assetDeleteCharacterConfirm(_ name: String) -> String {
        current == .english ? "Are you sure you want to delete \"\(name)\"?" : "确定要删除 \"\(name)\" 吗？"
    }

    // MARK: - Nest View

    static var nestSearchPlaceholder: String {
        current == .english ? "Search pets..." : "搜索宠物..."
    }

    static var nestCharacters: String {
        current == .english ? "characters" : "个角色"
    }

    static var nestAllCharacters: String {
        current == .english ? "All Characters" : "全部角色"
    }

    static var nestFavorites: String {
        current == .english ? "Favorites" : "收藏"
    }

    static var nestRecent: String {
        current == .english ? "Recent" : "最近"
    }

    static var nestNoCharactersFound: String {
        current == .english ? "No characters found" : "没有找到角色"
    }

    static func nestNoResultsFor(_ query: String) -> String {
        current == .english ? "No results for \"\(query)\"" : "没有找到 \"\(query)\" 的结果"
    }

    static var nestImportMore: String {
        current == .english ? "Import more characters using the Import button" : "使用导入按钮导入更多角色"
    }

    static var nestImportCharacters: String {
        current == .english ? "Import Characters" : "导入角色"
    }

    static var nestClearSearch: String {
        current == .english ? "Clear Search" : "清除搜索"
    }

    static var nestDropToDeployActive: String {
        current == .english ? "Release to deploy" : "松开以部署"
    }

    static var nestDropToDeploy: String {
        current == .english ? "Drag a character here to deploy to desktop" : "拖拽角色到此处部署到桌面"
    }

    static var nestDesktopPets: String {
        current == .english ? "Desktop Pets" : "桌面宠物"
    }

    static var nestRemoveAll: String {
        current == .english ? "Remove All" : "全部移除"
    }

    static var nestNoDesktopPets: String {
        current == .english ? "No desktop pets deployed" : "没有部署桌面宠物"
    }

    static var nestActive: String {
        current == .english ? "Active" : "活跃"
    }

    static var nestHidden: String {
        current == .english ? "Hidden" : "隐藏"
    }

    // MARK: - Category Sidebar

    static var sidebarAll: String {
        current == .english ? "All" : "全部"
    }

    static var sidebarCategories: String {
        current == .english ? "CATEGORIES" : "分类"
    }
}
