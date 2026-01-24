//
//  AssetPack.swift
//  Nano Pet
//
//  素材包数据模型 - 定义 .dreampet 格式
//

import Foundation
import AppKit
import Combine

// MARK: - Asset Pack Model

struct AssetPack: Identifiable, Codable {
    let id: UUID
    var name: String
    var author: String
    var version: String
    var style: String
    var size: CGSize
    var animations: [String: AnimationData]
    var behaviors: BehaviorSettings
    var createdAt: Date
    var previewImagePath: String?

    struct AnimationData: Codable {
        let file: String  // 文件名或目录
        let frames: [String]?  // 帧文件列表（用于 PNG 序列）
        let frameCount: Int
        let loop: Bool
        let fps: Int

        init(file: String, frames: [String]? = nil, frameCount: Int = 1, loop: Bool = true, fps: Int = 8) {
            self.file = file
            self.frames = frames
            self.frameCount = frameCount
            self.loop = loop
            self.fps = fps
        }
    }

    struct BehaviorSettings: Codable {
        var idleChance: Double
        var walkChance: Double
        var sleepChance: Double
        var jumpChance: Double

        init(idleChance: Double = 0.5, walkChance: Double = 0.3, sleepChance: Double = 0.1, jumpChance: Double = 0.1) {
            self.idleChance = idleChance
            self.walkChance = walkChance
            self.sleepChance = sleepChance
            self.jumpChance = jumpChance
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        author: String = "Unknown",
        version: String = "1.0",
        style: String = "pixel",
        size: CGSize = CGSize(width: 128, height: 128),
        animations: [String: AnimationData] = [:],
        behaviors: BehaviorSettings = BehaviorSettings(),
        createdAt: Date = Date(),
        previewImagePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.author = author
        self.version = version
        self.style = style
        self.size = size
        self.animations = animations
        self.behaviors = behaviors
        self.createdAt = createdAt
        self.previewImagePath = previewImagePath
    }
}

// MARK: - Manifest (JSON配置文件)

struct AssetPackManifest: Codable {
    let name: String
    let version: String
    let author: String?
    let style: String?
    let size: SizeConfig?
    let animations: [String: AnimationConfig]?
    let behaviors: BehaviorConfig?

    struct SizeConfig: Codable {
        let width: Int
        let height: Int
    }

    struct AnimationConfig: Codable {
        let file: String?
        let files: [String]?
        let loop: Bool?
        let fps: Int?
    }

    struct BehaviorConfig: Codable {
        let idle_chance: Double?
        let walk_chance: Double?
        let sleep_chance: Double?
        let jump_chance: Double?
    }
}

// MARK: - Loaded Pet (运行时使用的宠物数据)

class LoadedPet: Identifiable, ObservableObject {
    let id: UUID
    let assetPack: AssetPack
    let basePath: URL

    // 缓存的动画帧
    @Published var animationFrames: [String: [NSImage]] = [:]
    @Published var previewImage: NSImage?

    init(assetPack: AssetPack, basePath: URL) {
        self.id = assetPack.id
        self.assetPack = assetPack
        self.basePath = basePath
    }

    // 加载动画帧
    func loadAnimationFrames(for action: String) -> [NSImage] {
        if let cached = animationFrames[action] {
            return cached
        }

        guard let animData = assetPack.animations[action] else {
            return []
        }

        var frames: [NSImage] = []

        if let frameFiles = animData.frames {
            // PNG 序列
            for frameName in frameFiles {
                let framePath = basePath.appendingPathComponent("animations").appendingPathComponent(frameName)
                if let image = NSImage(contentsOf: framePath) {
                    frames.append(image)
                }
            }
        } else {
            // 单个文件或 sprite sheet
            let filePath = basePath.appendingPathComponent("animations").appendingPathComponent(animData.file)
            if let image = NSImage(contentsOf: filePath) {
                // TODO: 如果是 sprite sheet，需要切分
                frames.append(image)
            }
        }

        animationFrames[action] = frames
        return frames
    }

    // 加载预览图
    func loadPreviewImage() {
        if let previewPath = assetPack.previewImagePath {
            let fullPath = basePath.appendingPathComponent(previewPath)
            previewImage = NSImage(contentsOf: fullPath)
        } else {
            // 尝试使用 idle 动画的第一帧
            let idleFrames = loadAnimationFrames(for: "idle")
            previewImage = idleFrames.first
        }
    }
}

// MARK: - Pet Category Model

struct PetCategory: Identifiable, Hashable {
    let id: String           // e.g., "pokemon"
    let name: String         // e.g., "Pokemon"
    let emoji: String        // e.g., "⚡"
    var characters: [String] // e.g., ["pikachu", "eevee", ...]
    var superCategory: String? // e.g., "Games", "Anime"

    var count: Int { characters.count }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PetCategory, rhs: PetCategory) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Super Category (for grouping)

struct SuperCategory: Identifiable {
    let id: String
    let name: String
    let emoji: String
    var categories: [PetCategory]

    var totalCount: Int {
        categories.reduce(0) { $0 + $1.count }
    }
}

// MARK: - Category Detection

struct CategoryDetector {
    // Known franchise patterns for category detection
    static let franchisePatterns: [String: (name: String, emoji: String, superCategory: String)] = [
        // Games
        "pokemon": ("Pokemon", "⚡", "Games"),
        "digimon": ("Digimon", "🔥", "Games"),
        "genshin": ("Genshin Impact", "🌍", "Games"),
        "undertale": ("Undertale", "❤️", "Games"),
        "deltarune": ("Deltarune", "💜", "Games"),
        "minecraft": ("Minecraft", "⛏️", "Games"),
        "zelda": ("Zelda", "🗡️", "Games"),
        "mario": ("Mario", "🍄", "Games"),
        "kirby": ("Kirby", "🌸", "Games"),
        "sonic": ("Sonic", "💨", "Games"),
        "animal-crossing": ("Animal Crossing", "🏝️", "Games"),
        "hollow-knight": ("Hollow Knight", "🦋", "Games"),
        "stardew": ("Stardew Valley", "🌾", "Games"),
        "terraria": ("Terraria", "🌳", "Games"),
        "fnaf": ("FNAF", "🐻", "Games"),

        // Anime
        "naruto": ("Naruto", "🍥", "Anime"),
        "one-piece": ("One Piece", "⛵", "Anime"),
        "onepiece": ("One Piece", "⛵", "Anime"),
        "attack-on-titan": ("Attack on Titan", "🗡️", "Anime"),
        "aot": ("Attack on Titan", "🗡️", "Anime"),
        "demon-slayer": ("Demon Slayer", "🌙", "Anime"),
        "kimetsu": ("Demon Slayer", "🌙", "Anime"),
        "my-hero-academia": ("My Hero Academia", "💪", "Anime"),
        "mha": ("My Hero Academia", "💪", "Anime"),
        "boku-no-hero": ("My Hero Academia", "💪", "Anime"),
        "jujutsu-kaisen": ("Jujutsu Kaisen", "👁️", "Anime"),
        "jjk": ("Jujutsu Kaisen", "👁️", "Anime"),
        "dragon-ball": ("Dragon Ball", "🐉", "Anime"),
        "dbz": ("Dragon Ball", "🐉", "Anime"),
        "fairy-tail": ("Fairy Tail", "🧚", "Anime"),
        "hunter-x-hunter": ("Hunter x Hunter", "🎯", "Anime"),
        "hxh": ("Hunter x Hunter", "🎯", "Anime"),
        "death-note": ("Death Note", "📓", "Anime"),
        "fullmetal": ("Fullmetal Alchemist", "⚙️", "Anime"),
        "fma": ("Fullmetal Alchemist", "⚙️", "Anime"),
        "evangelion": ("Evangelion", "🤖", "Anime"),
        "sailor-moon": ("Sailor Moon", "🌙", "Anime"),
        "studio-ghibli": ("Studio Ghibli", "🌲", "Anime"),
        "ghibli": ("Studio Ghibli", "🌲", "Anime"),
        "totoro": ("Studio Ghibli", "🌲", "Anime"),
        "spirited": ("Studio Ghibli", "🌲", "Anime"),
        "spy-x-family": ("Spy x Family", "🕵️", "Anime"),
        "chainsaw-man": ("Chainsaw Man", "🪚", "Anime"),
        "bocchi": ("Bocchi the Rock", "🎸", "Anime"),
        "konosuba": ("Konosuba", "🔮", "Anime"),
        "re-zero": ("Re:Zero", "❄️", "Anime"),
        "sword-art": ("Sword Art Online", "⚔️", "Anime"),
        "sao": ("Sword Art Online", "⚔️", "Anime"),
        "mob-psycho": ("Mob Psycho 100", "💫", "Anime"),
        "one-punch": ("One Punch Man", "👊", "Anime"),
        "opm": ("One Punch Man", "👊", "Anime"),
        "cowboy-bebop": ("Cowboy Bebop", "🚀", "Anime"),
        "jojo": ("JoJo's Bizarre Adventure", "⭐", "Anime"),
        "haikyuu": ("Haikyuu", "🏐", "Anime"),
        "blue-lock": ("Blue Lock", "⚽", "Anime"),
        "bleach": ("Bleach", "💀", "Anime"),
        "black-clover": ("Black Clover", "☘️", "Anime"),
        "fire-force": ("Fire Force", "🔥", "Anime"),
        "tokyo-ghoul": ("Tokyo Ghoul", "👹", "Anime"),
        "bungo-stray": ("Bungo Stray Dogs", "🐕", "Anime"),
        "horimiya": ("Horimiya", "💕", "Anime"),
        "toradora": ("Toradora", "🐯", "Anime"),
        "kaguya": ("Kaguya-sama", "💝", "Anime"),
        "quintessential": ("Quintessential Quintuplets", "🎀", "Anime"),
        "oshi-no-ko": ("Oshi no Ko", "⭐", "Anime"),
        "frieren": ("Frieren", "🧝", "Anime"),

        // Vtubers
        "hololive": ("Hololive", "🎭", "Vtubers"),
        "nijisanji": ("Nijisanji", "🌈", "Vtubers"),
        "vshojo": ("VShojo", "💋", "Vtubers"),
        "vtuber": ("Vtubers", "📺", "Vtubers"),

        // Western
        "disney": ("Disney", "🏰", "Western"),
        "pixar": ("Pixar", "🎬", "Western"),
        "cartoon-network": ("Cartoon Network", "📺", "Western"),
        "adventure-time": ("Adventure Time", "🗡️", "Western"),
        "steven-universe": ("Steven Universe", "💎", "Western"),
        "gravity-falls": ("Gravity Falls", "🌲", "Western"),
        "amphibia": ("Amphibia", "🐸", "Western"),
        "owl-house": ("The Owl House", "🦉", "Western"),
        "mlp": ("My Little Pony", "🦄", "Western"),
        "spongebob": ("SpongeBob", "🧽", "Western"),
        "rick-morty": ("Rick and Morty", "🛸", "Western"),
        "simpsons": ("The Simpsons", "🍩", "Western"),
        "futurama": ("Futurama", "🚀", "Western"),
        "south-park": ("South Park", "🏔️", "Western"),
        "family-guy": ("Family Guy", "🏠", "Western"),
        "marvel": ("Marvel", "🦸", "Western"),
        "dc": ("DC Comics", "🦇", "Western"),
        "star-wars": ("Star Wars", "⚔️", "Western"),
        "harry-potter": ("Harry Potter", "⚡", "Western"),
        "lotr": ("Lord of the Rings", "💍", "Western"),

        // Memes
        "meme": ("Memes", "😂", "Memes"),
        "doge": ("Memes", "🐕", "Memes"),
        "pepe": ("Memes", "🐸", "Memes"),
        "wojak": ("Memes", "😐", "Memes"),
        "nyan": ("Memes", "🌈", "Memes"),
        "trollface": ("Memes", "🃏", "Memes"),

        // Other
        "sanrio": ("Sanrio", "🎀", "Other"),
        "hello-kitty": ("Sanrio", "🐱", "Other"),
        "kuromi": ("Sanrio", "💜", "Other"),
        "cinnamoroll": ("Sanrio", "☁️", "Other"),
        "tamagotchi": ("Tamagotchi", "🥚", "Other"),
        "among-us": ("Among Us", "📮", "Other"),
        "fall-guys": ("Fall Guys", "🫘", "Other"),
    ]

    // Super category definitions
    static let superCategories: [String: (name: String, emoji: String)] = [
        "Games": ("Games", "🎮"),
        "Anime": ("Anime", "⚔️"),
        "Vtubers": ("Vtubers", "📺"),
        "Western": ("Western", "🎬"),
        "Memes": ("Memes", "😂"),
        "Other": ("Other", "✨"),
    ]

    /// Detect category from folder name
    static func detectCategory(from folderName: String) -> (id: String, name: String, emoji: String, superCategory: String)? {
        let lowercased = folderName.lowercased()

        // Try exact match first
        if let match = franchisePatterns[lowercased] {
            return (lowercased, match.name, match.emoji, match.superCategory)
        }

        // Try prefix matching (e.g., "pokemon-pikachu" -> "pokemon")
        for (key, value) in franchisePatterns {
            if lowercased.hasPrefix(key + "-") || lowercased.hasPrefix(key + "_") {
                return (key, value.name, value.emoji, value.superCategory)
            }
            // Also check if the folder name contains the key
            if lowercased.contains(key) {
                return (key, value.name, value.emoji, value.superCategory)
            }
        }

        return nil
    }

    /// Extract character name from folder name
    static func extractCharacterName(from folderName: String, categoryId: String?) -> String {
        var name = folderName

        // Remove category prefix if present
        if let catId = categoryId {
            let prefixes = [catId + "-", catId + "_", catId]
            for prefix in prefixes {
                if name.lowercased().hasPrefix(prefix) {
                    name = String(name.dropFirst(prefix.count))
                    break
                }
            }
        }

        // Remove common suffixes like "-by-author"
        if let byIndex = name.lowercased().range(of: "-by-") {
            name = String(name[..<byIndex.lowerBound])
        }

        // Convert kebab-case to Title Case
        let words = name.components(separatedBy: CharacterSet(charactersIn: "-_"))
        return words.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }
}

// MARK: - Pet 导入配置

struct PetImportConfig {
    // 动画名称模式匹配
    static let animationPatterns: [String: [String]] = [
        "idle": ["shime1", "shime2", "shime3", "shime4", "stand", "idle", "wait"],
        "walk": ["walk", "move", "shime1[0-9]", "run"],
        "sleep": ["sleep", "zzz", "rest", "nap"],
        "jump": ["jump", "leap", "hop"],
        "fall": ["fall", "drop", "descend"],
        "climb": ["climb", "wall", "crawl"],
        "sit": ["sit", "crouch", "squat"],
        "drag": ["drag", "held", "grab"]
    ]

    // 根据文件名推断动画类型
    static func inferAnimationType(from filename: String) -> String? {
        let lowercased = filename.lowercased()

        for (animType, patterns) in animationPatterns {
            for pattern in patterns {
                if lowercased.contains(pattern) {
                    return animType
                }
            }
        }

        return nil
    }

    // 对文件名进行自然排序
    static func sortFrameFiles(_ files: [String]) -> [String] {
        return files.sorted { lhs, rhs in
            let lhsNum = extractNumber(from: lhs)
            let rhsNum = extractNumber(from: rhs)
            if lhsNum != rhsNum {
                return lhsNum < rhsNum
            }
            return lhs < rhs
        }
    }

    private static func extractNumber(from string: String) -> Int {
        let pattern = "[0-9]+"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
           let range = Range(match.range, in: string) {
            return Int(string[range]) ?? 0
        }
        return 0
    }
}
