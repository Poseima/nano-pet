//
//  SpriteFrameCache.swift
//  Nano Pet
//
//  全局精灵帧缓存 - 所有同角色宠物共享图片资源
//

import AppKit

/// Shimeji sprite constants
/// Standard Shimeji-ee uses 46 frames (shime1.png to shime46.png)
enum ShimejiSpriteConstants {
    static let totalFrames = 46
    static let spriteWidth: CGFloat = 128
    static let spriteHeight: CGFloat = 128
}

/// 精灵帧全局缓存
/// 解决问题：每个宠物实例都独立加载46张图片，10只宠物 = 46MB 内存
/// 优化后：同角色宠物共享一份图片，10只同角色宠物 ≈ 4.6MB
@Observable
class SpriteFrameCache {
    static let shared = SpriteFrameCache()

    /// 缓存结构: [角色名: [帧编号: 图片]]
    private var cache: [String: [Int: NSImage]] = [:]

    /// 加载状态追踪
    private var loadingNames: Set<String> = []

    private init() {}

    // MARK: - Public API

    /// 获取指定角色的所有精灵帧
    /// - Parameter petName: 角色名 (如 "Agumon")
    /// - Returns: 帧编号到图片的映射
    func getFrames(for petName: String) -> [Int: NSImage] {
        // 如果已缓存，直接返回
        if let cached = cache[petName] {
            return cached
        }

        // 同步加载并缓存
        let frames = loadFramesFromDisk(for: petName)
        cache[petName] = frames
        return frames
    }

    /// 预加载角色帧（后台异步）
    /// - Parameter petName: 角色名
    func preload(petName: String) {
        guard cache[petName] == nil, !loadingNames.contains(petName) else { return }

        loadingNames.insert(petName)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let frames = self?.loadFramesFromDisk(for: petName) ?? [:]

            DispatchQueue.main.async {
                self?.cache[petName] = frames
                self?.loadingNames.remove(petName)
            }
        }
    }

    /// 清除指定角色的缓存
    func evict(petName: String) {
        cache.removeValue(forKey: petName)
    }

    /// 清除所有缓存
    func evictAll() {
        cache.removeAll()
    }

    /// 获取当前缓存的角色数量
    var cachedCount: Int {
        cache.count
    }

    /// 获取缓存的角色名列表
    var cachedNames: [String] {
        Array(cache.keys)
    }

    /// Get a frame by image name (e.g., "shime1")
    /// - Parameters:
    ///   - imageName: Frame name like "shime1" through "shime46"
    ///   - petName: Character name to look up in cache
    /// - Returns: The NSImage if found, nil otherwise
    func getFrame(named imageName: String, for petName: String) -> NSImage? {
        guard let frameNum = Int(imageName.replacingOccurrences(of: "shime", with: "")) else {
            return nil
        }
        return getFrames(for: petName)[frameNum]
    }

    /// Get a frame by number
    /// - Parameters:
    ///   - frameNumber: Frame number 1-46
    ///   - petName: Character name to look up in cache
    /// - Returns: The NSImage if found, nil otherwise
    func getFrame(_ frameNumber: Int, for petName: String) -> NSImage? {
        return getFrames(for: petName)[frameNumber]
    }

    // MARK: - Private

    private func loadFramesFromDisk(for petName: String) -> [Int: NSImage] {
        var frames: [Int: NSImage] = [:]
        let manager = AssetPackManager.shared

        // First: Try to load from characterPathMap (handles both hierarchical and flat structures)
        if let spritePath = manager.getSpritePath(for: petName) {
            print("[SpriteFrameCache] Loading '\(petName)' from characterPathMap: \(spritePath.path)")
            frames = loadFramesFromPath(spritePath)
            if !frames.isEmpty {
                print("[SpriteFrameCache] Successfully loaded \(frames.count) frames for '\(petName)'")
                return frames
            }
            print("[SpriteFrameCache] Warning: characterPathMap path exists but no frames found")
        }

        // Fallback: Load from Bundle resources (NanoPetAssets - flat structure)
        if frames.isEmpty, let resourcePath = Bundle.main.resourcePath {
            let bundlePath = URL(fileURLWithPath: resourcePath).appendingPathComponent("NanoPetAssets/\(petName)")
            print("[SpriteFrameCache] Trying Bundle flat path: \(bundlePath.path)")
            frames = loadFramesFromPath(bundlePath)
        }

        // Fallback: Load from Application Support/Pets
        if frames.isEmpty {
            let petPath = manager.petAssetsPath.appendingPathComponent(petName)
            print("[SpriteFrameCache] Trying Application Support path: \(petPath.path)")
            frames = loadFramesFromPath(petPath)
        }

        // Fallback: Load from Asset Catalog
        if frames.isEmpty {
            print("[SpriteFrameCache] Trying Asset Catalog fallback")
            for i in 1...ShimejiSpriteConstants.totalFrames {
                if let image = NSImage(named: "shime\(i)") {
                    frames[i] = image
                }
            }
        }

        if frames.isEmpty {
            print("[SpriteFrameCache] ERROR: Failed to load any frames for '\(petName)'")
        } else {
            print("[SpriteFrameCache] Loaded \(frames.count) frames for '\(petName)'")
        }
        return frames
    }

    /// Load frames from a specific directory path
    private func loadFramesFromPath(_ path: URL) -> [Int: NSImage] {
        var frames: [Int: NSImage] = [:]

        guard FileManager.default.fileExists(atPath: path.path) else {
            return frames
        }

        // Load frames shime1.png through shime46.png
        for i in 1...ShimejiSpriteConstants.totalFrames {
            let filePath = path.appendingPathComponent("shime\(i).png")
            if let image = NSImage(contentsOf: filePath) {
                frames[i] = image
            }
        }

        return frames
    }
}
