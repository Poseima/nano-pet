//
//  AssetPackManager.swift
//  Nano Pet
//
//  素材包管理器 - 导入、加载、管理素材包
//

import Foundation
import AppKit
import UniformTypeIdentifiers
import SwiftUI

// MARK: - Asset Pack Manager

@Observable
class AssetPackManager {
    static let shared = AssetPackManager()

    // 已安装的素材包
    private(set) var installedPacks: [AssetPack] = []

    // 当前加载的宠物
    private(set) var loadedPets: [LoadedPet] = []

    // 导入状态
    var isImporting: Bool = false
    var importProgress: Double = 0
    var importStatus: String = ""

    // MARK: - Category Management

    // Cached categories
    private(set) var categories: [PetCategory] = []
    private(set) var superCategories: [SuperCategory] = []

    // Character to category mapping (for quick lookup)
    private var characterCategoryMap: [String: String] = [:]

    // Character to full path mapping
    private var characterPathMap: [String: URL] = [:]

    // Search index
    var searchText: String = ""
    var selectedCategoryId: String? = nil
    var selectedSuperCategoryId: String? = nil

    // Favorites (persisted)
    var favorites: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: "favoriteCharacters") ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "favoriteCharacters")
        }
    }

    // Recent characters (persisted)
    var recentCharacters: [String] {
        get {
            UserDefaults.standard.stringArray(forKey: "recentCharacters") ?? []
        }
        set {
            let limited = Array(newValue.prefix(20))
            UserDefaults.standard.set(limited, forKey: "recentCharacters")
        }
    }

    // MARK: - Pet 管理

    // 当前使用的 Pet 名称 (使用 UserDefaults 持久化)
    var currentPet: String {
        get { UserDefaults.standard.string(forKey: "currentPet") ?? "Agumon" }
        set {
            UserDefaults.standard.set(newValue, forKey: "currentPet")
            NotificationCenter.default.post(name: .petChanged, object: newValue)
        }
    }

    // Pet 资源目录 (使用 Application Support，无需权限)
    var petAssetsPath: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let petsDir = appSupport.appendingPathComponent("DreamPet/Pets")

        // 确保目录存在
        try? FileManager.default.createDirectory(at: petsDir, withIntermediateDirectories: true)

        return petsDir
    }


    // 存储路径
    private var assetPacksDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dreamPetDir = appSupport.appendingPathComponent("DreamPet/AssetPacks")

        // 确保目录存在
        try? FileManager.default.createDirectory(at: dreamPetDir, withIntermediateDirectories: true)

        return dreamPetDir
    }

    init() {
        migrateUserDefaults()
        migrateOldPets()
        loadInstalledPacks()
        scanAndBuildCategories()
    }

    /// 迁移旧版 UserDefaults 键名
    private func migrateUserDefaults() {
        let defaults = UserDefaults.standard

        // 迁移 currentShimeji -> currentPet
        if let oldValue = defaults.string(forKey: "currentShimeji") {
            if defaults.string(forKey: "currentPet") == nil {
                defaults.set(oldValue, forKey: "currentPet")
            }
            defaults.removeObject(forKey: "currentShimeji")
        }

        // 迁移 shimejiName -> petName (在 pet_states 中)
        if var states = defaults.array(forKey: "pet_states") as? [[String: Any]] {
            var needsMigration = false
            for i in 0..<states.count {
                if let shimejiName = states[i]["shimejiName"] as? String {
                    states[i]["petName"] = shimejiName
                    states[i].removeValue(forKey: "shimejiName")
                    needsMigration = true
                }
            }
            if needsMigration {
                defaults.set(states, forKey: "pet_states")
            }
        }
    }

    /// 迁移旧版 Pets 到新位置
    private func migrateOldPets() {
        // 从旧的 Shimejis 目录迁移
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let oldPath = appSupport.appendingPathComponent("DreamPet/Shimejis")
        let newPath = petAssetsPath

        if FileManager.default.fileExists(atPath: oldPath.path) {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: oldPath.path)
                for item in contents {
                    let source = oldPath.appendingPathComponent(item)
                    let dest = newPath.appendingPathComponent(item)

                    // 如果目标不存在，则迁移
                    if !FileManager.default.fileExists(atPath: dest.path) {
                        try? FileManager.default.copyItem(at: source, to: dest)
                    }
                }
                // 删除旧目录
                try? FileManager.default.removeItem(at: oldPath)
                print("已迁移 Pets 到新位置")
            } catch {
                print("迁移失败: \(error)")
            }
        }
    }

    // MARK: - Pet Error

    enum PetError: LocalizedError {
        case invalidURL
        case importFailed
        case alreadyExists

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "无效的文件路径"
            case .importFailed:
                return "导入失败，请检查文件格式"
            case .alreadyExists:
                return "该角色已存在"
            }
        }
    }

    /// 获取已导入的 Pet 列表
    func listDownloadedPets() -> [String] {
        // 首先检查 Bundle 中的资源
        var bundlePets: [String] = []
        if let resourcePath = Bundle.main.resourcePath {
            let bundleAssetsPath = (resourcePath as NSString).appendingPathComponent("NanoPetAssets")
            if FileManager.default.fileExists(atPath: bundleAssetsPath) {
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: bundleAssetsPath) {
                    bundlePets = contents.filter { name in
                        let path = (bundleAssetsPath as NSString).appendingPathComponent(name)
                        var isDir: ObjCBool = false
                        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
                    }
                }
            }
        }

        // 然后检查 Application Support 中用户导入的资源
        var userPets: [String] = []
        if FileManager.default.fileExists(atPath: petAssetsPath.path) {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: petAssetsPath.path) {
                userPets = contents.filter { name in
                    let path = petAssetsPath.appendingPathComponent(name)
                    var isDir: ObjCBool = false
                    return FileManager.default.fileExists(atPath: path.path, isDirectory: &isDir) && isDir.boolValue
                }
            }
        }

        // 合并并去重
        var allPets = Set(bundlePets)
        allPets.formUnion(userPets)
        return Array(allPets).sorted()
    }

    /// 切换当前 Pet
    func switchPet(to name: String) {
        currentPet = name
    }

    /// 删除 Pet
    func deletePet(_ name: String) throws {
        let path = petAssetsPath.appendingPathComponent(name)
        try FileManager.default.removeItem(at: path)

        // 如果删除的是当前使用的，切换到第一个可用的
        if currentPet == name {
            let available = listDownloadedPets()
            if let first = available.first {
                currentPet = first
            }
        }
    }

    /// 加载 Pet 预览图
    func loadPetPreview(_ name: String) -> NSImage? {
        // First check the character path map (includes all sources)
        if let spritePath = characterPathMap[name] {
            let previewPath = spritePath.appendingPathComponent("shime1.png")
            if let image = NSImage(contentsOf: previewPath) {
                return image
            }
        }

        // Fallback: Check Bundle 资源
        if let resourcePath = Bundle.main.resourcePath {
            let bundlePath = (resourcePath as NSString).appendingPathComponent("NanoPetAssets/\(name)/shime1.png")
            if let image = NSImage(contentsOfFile: bundlePath) {
                return image
            }
        }

        // Fallback: Check Application Support
        let path = petAssetsPath.appendingPathComponent(name).appendingPathComponent("shime1.png")
        return NSImage(contentsOf: path)
    }

    /// Get sprite path for a character
    func getSpritePath(for character: String) -> URL? {
        return characterPathMap[character]
    }

    // MARK: - Category Scanning

    /// Scan all resources and build category structure
    func scanAndBuildCategories() {
        var categoryDict: [String: PetCategory] = [:]
        characterCategoryMap.removeAll()
        characterPathMap.removeAll()

        // 1. Scan bundle resources (NanoPetAssets folder in app bundle)
        //    This now contains both hierarchical (category/character/img/) and flat (character/shime*.png) structures
        if let resourcePath = Bundle.main.resourcePath {
            let bundlePath = URL(fileURLWithPath: resourcePath).appendingPathComponent("NanoPetAssets")

            // First scan hierarchical structure (category folders containing character folders)
            scanHierarchicalResources(at: bundlePath, into: &categoryDict)

            // Then scan flat structure for legacy pets (direct character folders with sprites)
            scanFlatResources(at: bundlePath, into: &categoryDict)
        }

        // 2. Scan user imported pets in Application Support (flat structure)
        scanFlatResources(at: petAssetsPath, into: &categoryDict)

        // 3. Build category list sorted by name
        categories = categoryDict.values.sorted { $0.name < $1.name }

        // 4. Build super categories
        buildSuperCategories()

        print("[AssetPackManager] Loaded \(categories.count) categories with \(characterPathMap.count) total characters")
    }

    /// Scan hierarchical folder structure: category/character/img/
    private func scanHierarchicalResources(at basePath: URL, into categoryDict: inout [String: PetCategory]) {
        guard FileManager.default.fileExists(atPath: basePath.path) else { return }

        guard let categoryFolders = try? FileManager.default.contentsOfDirectory(
            at: basePath,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for categoryFolder in categoryFolders {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: categoryFolder.path, isDirectory: &isDir),
                  isDir.boolValue else { continue }

            let categoryFolderName = categoryFolder.lastPathComponent

            // Detect category info from folder name
            let categoryInfo = CategoryDetector.detectCategory(from: categoryFolderName)
            let categoryId = categoryInfo?.id ?? categoryFolderName.lowercased()
            let categoryName = categoryInfo?.name ?? categoryFolderName.capitalized
            let categoryEmoji = categoryInfo?.emoji ?? "📁"
            let superCategory = categoryInfo?.superCategory ?? "Other"

            // Scan character folders inside this category
            guard let characterFolders = try? FileManager.default.contentsOfDirectory(
                at: categoryFolder,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for characterFolder in characterFolders {
                var isCharDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: characterFolder.path, isDirectory: &isCharDir),
                      isCharDir.boolValue else { continue }

                let characterFolderName = characterFolder.lastPathComponent

                // Check if this folder has sprites (either directly or in img subfolder)
                let imgFolder = characterFolder.appendingPathComponent("img")
                let spritePath: URL

                if FileManager.default.fileExists(atPath: imgFolder.path) {
                    spritePath = imgFolder
                } else {
                    spritePath = characterFolder
                }

                // Verify there are sprite files
                let hasSprites = (try? FileManager.default.contentsOfDirectory(atPath: spritePath.path))?
                    .contains { $0.hasPrefix("shime") && $0.hasSuffix(".png") } ?? false

                guard hasSprites else { continue }

                // Add to category
                if categoryDict[categoryId] == nil {
                    categoryDict[categoryId] = PetCategory(
                        id: categoryId,
                        name: categoryName,
                        emoji: categoryEmoji,
                        characters: [],
                        superCategory: superCategory
                    )
                }

                categoryDict[categoryId]?.characters.append(characterFolderName)
                characterCategoryMap[characterFolderName] = categoryId
                characterPathMap[characterFolderName] = spritePath
            }
        }
    }

    /// Scan flat folder structure (legacy): character/shime*.png
    private func scanFlatResources(at basePath: URL, into categoryDict: inout [String: PetCategory]) {
        guard FileManager.default.fileExists(atPath: basePath.path) else { return }

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: basePath,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for folder in contents {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDir),
                  isDir.boolValue else { continue }

            let folderName = folder.lastPathComponent

            // Skip if already processed
            guard characterPathMap[folderName] == nil else { continue }

            // Check if this folder has sprites
            let hasSprites = (try? FileManager.default.contentsOfDirectory(atPath: folder.path))?
                .contains { $0.hasPrefix("shime") && $0.hasSuffix(".png") } ?? false

            guard hasSprites else { continue }

            // Try to detect category from folder name
            let categoryInfo = CategoryDetector.detectCategory(from: folderName)
            let categoryId = categoryInfo?.id ?? "uncategorized"
            let categoryName = categoryInfo?.name ?? "Uncategorized"
            let categoryEmoji = categoryInfo?.emoji ?? "📦"
            let superCategory = categoryInfo?.superCategory ?? "Other"

            // Add to category
            if categoryDict[categoryId] == nil {
                categoryDict[categoryId] = PetCategory(
                    id: categoryId,
                    name: categoryName,
                    emoji: categoryEmoji,
                    characters: [],
                    superCategory: superCategory
                )
            }

            categoryDict[categoryId]?.characters.append(folderName)
            characterCategoryMap[folderName] = categoryId
            characterPathMap[folderName] = folder
        }
    }

    /// Build super categories from categories
    private func buildSuperCategories() {
        var superCatDict: [String: SuperCategory] = [:]

        for category in categories {
            let superCatId = category.superCategory ?? "Other"
            let superCatInfo = CategoryDetector.superCategories[superCatId] ?? ("Other", "✨")

            if superCatDict[superCatId] == nil {
                superCatDict[superCatId] = SuperCategory(
                    id: superCatId,
                    name: superCatInfo.0,
                    emoji: superCatInfo.1,
                    categories: []
                )
            }

            superCatDict[superCatId]?.categories.append(category)
        }

        // Sort super categories in preferred order
        let order = ["Games", "Anime", "Vtubers", "Western", "Memes", "Other"]
        superCategories = order.compactMap { superCatDict[$0] }
    }

    /// Get all characters (flat list)
    func getAllCharacters() -> [String] {
        return Array(characterPathMap.keys).sorted()
    }

    /// Get characters for a specific category
    func getCharacters(for categoryId: String) -> [String] {
        return categories.first { $0.id == categoryId }?.characters ?? []
    }

    /// Get filtered characters based on search and selection
    func getFilteredCharacters() -> [String] {
        var result: [String]

        if let categoryId = selectedCategoryId {
            result = getCharacters(for: categoryId)
        } else if let superCatId = selectedSuperCategoryId {
            let cats = superCategories.first { $0.id == superCatId }?.categories ?? []
            result = cats.flatMap { $0.characters }
        } else {
            result = getAllCharacters()
        }

        // Apply search filter
        if !searchText.isEmpty {
            let search = searchText.lowercased()
            result = result.filter { $0.lowercased().contains(search) }
        }

        return result.sorted()
    }

    /// Get category for a character
    func getCategory(for character: String) -> PetCategory? {
        guard let categoryId = characterCategoryMap[character] else { return nil }
        return categories.first { $0.id == categoryId }
    }

    /// Get display name for a character
    func getDisplayName(for character: String) -> String {
        let categoryId = characterCategoryMap[character]
        return CategoryDetector.extractCharacterName(from: character, categoryId: categoryId)
    }

    /// Toggle favorite status for a character
    func toggleFavorite(_ character: String) {
        if favorites.contains(character) {
            favorites.remove(character)
        } else {
            favorites.insert(character)
        }
    }

    /// Add character to recent list
    func addToRecent(_ character: String) {
        var recent = recentCharacters
        recent.removeAll { $0 == character }
        recent.insert(character, at: 0)
        recentCharacters = recent
    }

    /// Get total character count
    var totalCharacterCount: Int {
        characterPathMap.count
    }

    // MARK: - Load Installed Packs

    func loadInstalledPacks() {
        installedPacks = []

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: assetPacksDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }

        for url in contents where url.hasDirectoryPath {
            let manifestURL = url.appendingPathComponent("manifest.json")
            if let data = try? Data(contentsOf: manifestURL),
               let manifest = try? JSONDecoder().decode(AssetPackManifest.self, from: data) {

                let pack = manifestToAssetPack(manifest, id: UUID(uuidString: url.lastPathComponent) ?? UUID())
                installedPacks.append(pack)
            }
        }
    }

    private func manifestToAssetPack(_ manifest: AssetPackManifest, id: UUID) -> AssetPack {
        var animations: [String: AssetPack.AnimationData] = [:]

        if let animConfigs = manifest.animations {
            for (name, config) in animConfigs {
                let files = config.files ?? (config.file != nil ? [config.file!] : [])
                animations[name] = AssetPack.AnimationData(
                    file: config.file ?? "",
                    frames: config.files,
                    frameCount: files.count,
                    loop: config.loop ?? true,
                    fps: config.fps ?? 8
                )
            }
        }

        let behaviors = AssetPack.BehaviorSettings(
            idleChance: manifest.behaviors?.idle_chance ?? 0.5,
            walkChance: manifest.behaviors?.walk_chance ?? 0.3,
            sleepChance: manifest.behaviors?.sleep_chance ?? 0.1,
            jumpChance: manifest.behaviors?.jump_chance ?? 0.1
        )

        return AssetPack(
            id: id,
            name: manifest.name,
            author: manifest.author ?? "Unknown",
            version: manifest.version,
            style: manifest.style ?? "pixel",
            size: CGSize(
                width: CGFloat(manifest.size?.width ?? 128),
                height: CGFloat(manifest.size?.height ?? 128)
            ),
            animations: animations,
            behaviors: behaviors,
            previewImagePath: "preview.png"
        )
    }

    // MARK: - Import Asset Pack

    func importAssetPack(from url: URL) async throws -> AssetPack {
        isImporting = true
        importProgress = 0
        importStatus = "正在分析文件..."

        defer {
            isImporting = false
        }

        let fileExtension = url.pathExtension.lowercased()

        switch fileExtension {
        case "zip":
            return try await importFromZip(url)
        case "dreampet":
            return try await importDreamPetPackage(url)
        default:
            // 尝试作为目录导入
            if url.hasDirectoryPath {
                return try await importFromDirectory(url)
            }
            throw ImportError.unsupportedFormat
        }
    }

    // MARK: - Import from ZIP

    private func importFromZip(_ url: URL) async throws -> AssetPack {
        importStatus = "正在解压文件..."
        importProgress = 0.1

        // 创建临时目录
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // 解压 ZIP (使用系统 unzip 命令)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", url.path, "-d", tempDir.path]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ImportError.unsupportedFormat
        }

        importProgress = 0.3
        importStatus = "正在分析素材..."

        // 查找图片文件
        let imageFiles = try findImageFiles(in: tempDir)

        guard !imageFiles.isEmpty else {
            throw ImportError.noImagesFound
        }

        importProgress = 0.5
        importStatus = "正在识别动画序列..."

        // 分析并分组动画
        let groupedAnimations = groupAnimations(from: imageFiles)

        // 获取图片尺寸
        var size = CGSize(width: 128, height: 128)
        if let firstImage = imageFiles.first,
           let image = NSImage(contentsOf: firstImage) {
            size = image.size
        }

        importProgress = 0.7
        importStatus = "正在创建素材包..."

        // 创建素材包
        let packId = UUID()
        let packDir = assetPacksDirectory.appendingPathComponent(packId.uuidString)
        try FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)

        let animationsDir = packDir.appendingPathComponent("animations")
        try FileManager.default.createDirectory(at: animationsDir, withIntermediateDirectories: true)

        // 复制文件并创建动画数据
        var animations: [String: AssetPack.AnimationData] = [:]

        for (animType, files) in groupedAnimations {
            let sortedFiles = PetImportConfig.sortFrameFiles(files.map { $0.lastPathComponent })
            var frameNames: [String] = []

            for file in files {
                let destName = "\(animType)_\(file.lastPathComponent)"
                let destPath = animationsDir.appendingPathComponent(destName)
                try FileManager.default.copyItem(at: file, to: destPath)
                frameNames.append(destName)
            }

            frameNames = PetImportConfig.sortFrameFiles(frameNames)

            animations[animType] = AssetPack.AnimationData(
                file: frameNames.first ?? "",
                frames: frameNames,
                frameCount: frameNames.count,
                loop: true,
                fps: 8
            )
        }

        // 复制预览图（使用第一帧）
        if let firstImage = imageFiles.first {
            let previewPath = packDir.appendingPathComponent("preview.png")
            try FileManager.default.copyItem(at: firstImage, to: previewPath)
        }

        importProgress = 0.9
        importStatus = "正在保存配置..."

        // 创建素材包对象
        let pack = AssetPack(
            id: packId,
            name: url.deletingPathExtension().lastPathComponent,
            author: "Imported",
            version: "1.0",
            style: "pixel",
            size: size,
            animations: animations,
            behaviors: AssetPack.BehaviorSettings(),
            previewImagePath: "preview.png"
        )

        // 保存 manifest
        try saveManifest(for: pack, at: packDir)

        importProgress = 1.0
        importStatus = "导入完成！"

        installedPacks.append(pack)
        return pack
    }

    // MARK: - Import DreamPet Package

    private func importDreamPetPackage(_ url: URL) async throws -> AssetPack {
        importStatus = "正在导入 DreamPet 包..."
        importProgress = 0.3

        // .dreampet 实际上是一个目录或 zip
        if url.hasDirectoryPath {
            return try await importFromDirectory(url)
        } else {
            // 作为 zip 处理
            return try await importFromZip(url)
        }
    }

    // MARK: - Import from Directory

    private func importFromDirectory(_ url: URL) async throws -> AssetPack {
        importStatus = "正在分析目录..."
        importProgress = 0.2

        let manifestURL = url.appendingPathComponent("manifest.json")

        if FileManager.default.fileExists(atPath: manifestURL.path) {
            // 有 manifest，直接读取
            let data = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(AssetPackManifest.self, from: data)

            importProgress = 0.5

            // 复制到 asset packs 目录
            let packId = UUID()
            let destDir = assetPacksDirectory.appendingPathComponent(packId.uuidString)
            try FileManager.default.copyItem(at: url, to: destDir)

            importProgress = 1.0
            importStatus = "导入完成！"

            let pack = manifestToAssetPack(manifest, id: packId)
            installedPacks.append(pack)
            return pack
        } else {
            // 没有 manifest，尝试自动分析
            let imageFiles = try findImageFiles(in: url)
            guard !imageFiles.isEmpty else {
                throw ImportError.noImagesFound
            }

            // 按目录自动分组
            let groupedAnimations = groupAnimations(from: imageFiles)

            // 创建素材包
            let packId = UUID()
            let packDir = assetPacksDirectory.appendingPathComponent(packId.uuidString)
            try FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)

            let animationsDir = packDir.appendingPathComponent("animations")
            try FileManager.default.createDirectory(at: animationsDir, withIntermediateDirectories: true)

            var animations: [String: AssetPack.AnimationData] = [:]

            for (animType, files) in groupedAnimations {
                var frameNames: [String] = []

                for file in files {
                    let destName = "\(animType)_\(file.lastPathComponent)"
                    let destPath = animationsDir.appendingPathComponent(destName)
                    try FileManager.default.copyItem(at: file, to: destPath)
                    frameNames.append(destName)
                }

                frameNames = PetImportConfig.sortFrameFiles(frameNames)

                animations[animType] = AssetPack.AnimationData(
                    file: frameNames.first ?? "",
                    frames: frameNames,
                    frameCount: frameNames.count,
                    loop: true,
                    fps: 8
                )
            }

            // 复制预览图
            if let firstImage = imageFiles.first {
                let previewPath = packDir.appendingPathComponent("preview.png")
                try FileManager.default.copyItem(at: firstImage, to: previewPath)
            }

            var size = CGSize(width: 128, height: 128)
            if let firstImage = imageFiles.first,
               let image = NSImage(contentsOf: firstImage) {
                size = image.size
            }

            let pack = AssetPack(
                id: packId,
                name: url.lastPathComponent,
                author: "Imported",
                version: "1.0",
                style: "pixel",
                size: size,
                animations: animations,
                behaviors: AssetPack.BehaviorSettings(),
                previewImagePath: "preview.png"
            )

            try saveManifest(for: pack, at: packDir)

            importProgress = 1.0
            importStatus = "导入完成！"

            installedPacks.append(pack)
            return pack
        }
    }

    // MARK: - Helper Methods

    private func findImageFiles(in directory: URL) throws -> [URL] {
        var imageFiles: [URL] = []

        let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        while let url = enumerator?.nextObject() as? URL {
            let ext = url.pathExtension.lowercased()
            if ["png", "jpg", "jpeg", "gif", "webp"].contains(ext) {
                imageFiles.append(url)
            }
        }

        return imageFiles
    }

    private func groupAnimations(from files: [URL]) -> [String: [URL]] {
        var groups: [String: [URL]] = [:]

        for file in files {
            let filename = file.deletingPathExtension().lastPathComponent

            if let animType = PetImportConfig.inferAnimationType(from: filename) {
                if groups[animType] == nil {
                    groups[animType] = []
                }
                groups[animType]?.append(file)
            } else {
                // 默认归为 idle
                if groups["idle"] == nil {
                    groups["idle"] = []
                }
                groups["idle"]?.append(file)
            }
        }

        // 如果只有 idle，尝试按数字序列重新分组
        if groups.count == 1 && groups["idle"] != nil {
            let allFiles = groups["idle"]!
            if allFiles.count > 8 {
                // 假设每个动画大约有 4-8 帧
                let framesPerAnim = min(8, allFiles.count / 3)
                let sorted = PetImportConfig.sortFrameFiles(allFiles.map { $0.lastPathComponent })

                groups = [:]
                let animTypes = ["idle", "walk", "jump"]

                for (index, filename) in sorted.enumerated() {
                    let animIndex = min(index / framesPerAnim, animTypes.count - 1)
                    let animType = animTypes[animIndex]

                    if groups[animType] == nil {
                        groups[animType] = []
                    }

                    if let file = allFiles.first(where: { $0.lastPathComponent == filename }) {
                        groups[animType]?.append(file)
                    }
                }
            }
        }

        return groups
    }

    private func saveManifest(for pack: AssetPack, at directory: URL) throws {
        var animConfigs: [String: AssetPackManifest.AnimationConfig] = [:]

        for (name, data) in pack.animations {
            animConfigs[name] = AssetPackManifest.AnimationConfig(
                file: data.file,
                files: data.frames,
                loop: data.loop,
                fps: data.fps
            )
        }

        let manifest = AssetPackManifest(
            name: pack.name,
            version: pack.version,
            author: pack.author,
            style: pack.style,
            size: AssetPackManifest.SizeConfig(
                width: Int(pack.size.width),
                height: Int(pack.size.height)
            ),
            animations: animConfigs,
            behaviors: AssetPackManifest.BehaviorConfig(
                idle_chance: pack.behaviors.idleChance,
                walk_chance: pack.behaviors.walkChance,
                sleep_chance: pack.behaviors.sleepChance,
                jump_chance: pack.behaviors.jumpChance
            )
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(manifest)
        try data.write(to: directory.appendingPathComponent("manifest.json"))
    }

    // MARK: - Load Pet

    func loadPet(from pack: AssetPack) -> LoadedPet {
        let packDir = assetPacksDirectory.appendingPathComponent(pack.id.uuidString)
        let loadedPet = LoadedPet(assetPack: pack, basePath: packDir)
        loadedPet.loadPreviewImage()
        loadedPets.append(loadedPet)
        return loadedPet
    }

    // MARK: - Delete Pack

    func deletePack(_ pack: AssetPack) throws {
        let packDir = assetPacksDirectory.appendingPathComponent(pack.id.uuidString)
        try FileManager.default.removeItem(at: packDir)
        installedPacks.removeAll { $0.id == pack.id }
        loadedPets.removeAll { $0.id == pack.id }
    }

    // MARK: - Shimeji-ee Format Detection

    /// Check if a directory is in Shimeji-ee format
    func detectShimejiFormat(at path: URL) -> Bool {
        // Check for conf/actions.xml
        let actionsPath = path.appendingPathComponent("conf/actions.xml")
        let behaviorsPath = path.appendingPathComponent("conf/behaviors.xml")
        let imgPath = path.appendingPathComponent("img")

        return FileManager.default.fileExists(atPath: actionsPath.path) ||
               FileManager.default.fileExists(atPath: behaviorsPath.path) ||
               FileManager.default.fileExists(atPath: imgPath.path)
    }

    /// Import a Shimeji-ee format pack
    /// - Parameter directory: Directory containing conf/actions.xml and img/
    /// - Returns: Name of the imported character
    func importShimejiPack(from directory: URL) async throws -> String {
        isImporting = true
        importProgress = 0.1
        importStatus = "检测 Shimeji-ee 格式..."

        defer {
            isImporting = false
        }

        guard detectShimejiFormat(at: directory) else {
            throw ImportError.unsupportedFormat
        }

        importProgress = 0.3
        importStatus = "解析配置文件..."

        // Get character name from directory
        let characterName = directory.lastPathComponent

        // Copy img folder to pet assets path
        let imgSource = directory.appendingPathComponent("img")
        let imgDest = petAssetsPath.appendingPathComponent(characterName)

        if FileManager.default.fileExists(atPath: imgSource.path) {
            try? FileManager.default.removeItem(at: imgDest)
            try FileManager.default.copyItem(at: imgSource, to: imgDest)
        }

        importProgress = 0.9
        importStatus = "更新索引..."

        // Refresh category cache
        scanAndBuildCategories()

        importProgress = 1.0
        importStatus = "导入完成！"

        return characterName
    }

    // MARK: - Config Loading

    /// Check if a character has animation config
    /// TODO: Implement AnimationConfigLoader when needed
    func hasAnimationConfig(for character: String) -> Bool {
        // Check if character directory has animation config files
        let configPath = petAssetsPath.appendingPathComponent(character).appendingPathComponent("config.json")
        return FileManager.default.fileExists(atPath: configPath.path)
    }

    /// Load animation config for a character
    /// TODO: Implement CharacterConfig when needed
    func loadAnimationConfig(for character: String) -> [String: Any]? {
        let configPath = petAssetsPath.appendingPathComponent(character).appendingPathComponent("config.json")
        guard let data = try? Data(contentsOf: configPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }

    // MARK: - Errors

    enum ImportError: LocalizedError {
        case unsupportedFormat
        case noImagesFound
        case invalidManifest
        case copyFailed
        case importFailed

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat:
                return "不支持的文件格式"
            case .noImagesFound:
                return "未找到图片文件"
            case .invalidManifest:
                return "无效的配置文件"
            case .copyFailed:
                return "文件复制失败"
            case .importFailed:
                return "导入失败"
            }
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let petChanged = Notification.Name("petChanged")
    static let petVisibilityChanged = Notification.Name("petVisibilityChanged")
    static let petScreenDidChange = Notification.Name("petScreenDidChange")
}
