//
//  OpenRouterService.swift
//  Nano Pet
//
//  OpenRouter API 服务 - 调用 Nano Banana Pro 生成宠物素材
//

import Foundation
import AppKit

// MARK: - API Models

struct OpenRouterRequest: Codable {
    let model: String
    let messages: [Message]
    let maxTokens: Int?

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
    }

    struct Message: Codable {
        let role: String
        let content: [ContentPart]
    }

    struct ContentPart: Codable {
        let type: String
        let text: String?
        let imageUrl: ImageURL?

        enum CodingKeys: String, CodingKey {
            case type
            case text
            case imageUrl = "image_url"
        }
    }

    struct ImageURL: Codable {
        let url: String
    }
}

struct OpenRouterResponse: Codable {
    let choices: [Choice]?
    let error: APIError?

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }

    struct APIError: Codable {
        let message: String
        let code: String?
    }
}

// MARK: - Generation Config

struct PetGenerationConfig {
    let petName: String
    let style: PetStyle
    let size: CGSize
    let actions: [PetAction]
    let referenceImage: Data?
    let customPrompt: String?

    enum PetStyle: String, CaseIterable {
        case pixel = "pixel"
        case watercolor = "watercolor"
        case flat = "flat"
        case anime = "anime"

        var promptDescription: String {
            switch self {
            case .pixel:
                return "pixel art, 8-bit retro style, limited color palette, crisp edges, no anti-aliasing"
            case .watercolor:
                return "soft watercolor painting style, gentle pastel colors, artistic brushstrokes, dreamy atmosphere"
            case .flat:
                return "flat design, vector illustration style, clean geometric shapes, solid colors, minimal shadows"
            case .anime:
                return "cute anime style, big expressive eyes, kawaii aesthetic, soft shading, vibrant colors"
            }
        }

        var displayName: String {
            switch self {
            case .pixel: return "像素风"
            case .watercolor: return "水彩风"
            case .flat: return "扁平风"
            case .anime: return "动漫风"
            }
        }
    }

    enum PetAction: String, CaseIterable {
        case idle = "idle"
        case walk = "walk"
        case jump = "jump"
        case sleep = "sleep"
        case sit = "sit"
        case climb = "climb"

        var displayName: String {
            switch self {
            case .idle: return "待机"
            case .walk: return "行走"
            case .jump: return "跳跃"
            case .sleep: return "睡觉"
            case .sit: return "坐下"
            case .climb: return "攀爬"
            }
        }

        var frameCount: Int {
            switch self {
            case .idle: return 3
            case .walk: return 4
            case .jump: return 3
            case .sleep: return 2
            case .sit: return 2
            case .climb: return 4
            }
        }

        func framePrompt(frameIndex: Int) -> String {
            switch self {
            case .idle:
                let frames = [
                    "standing still in relaxed pose, looking forward, calm expression",
                    "same standing pose, eyes half-closed in a slow blink",
                    "same standing pose, subtle tail/ear movement, content expression"
                ]
                return frames[min(frameIndex, frames.count - 1)]

            case .walk:
                let frames = [
                    "walking pose, left foot forward, body leaning slightly right",
                    "walking pose, mid-stride, both feet on ground",
                    "walking pose, right foot forward, body leaning slightly left",
                    "walking pose, completing stride, returning to neutral"
                ]
                return frames[min(frameIndex, frames.count - 1)]

            case .jump:
                let frames = [
                    "crouching down, preparing to jump, focused expression",
                    "mid-air jump, legs tucked, excited happy expression",
                    "landing from jump, legs extended, balanced pose"
                ]
                return frames[min(frameIndex, frames.count - 1)]

            case .sleep:
                let frames = [
                    "curled up sleeping, eyes closed, peaceful expression",
                    "same sleeping pose, with zzz effect, deep sleep"
                ]
                return frames[min(frameIndex, frames.count - 1)]

            case .sit:
                let frames = [
                    "sitting pose, tail wrapped around body, content expression",
                    "same sitting pose, head tilted slightly, curious look"
                ]
                return frames[min(frameIndex, frames.count - 1)]

            case .climb:
                let frames = [
                    "clinging to vertical surface, front paws reaching up",
                    "climbing motion, right paw extended higher",
                    "climbing motion, left paw extended higher",
                    "pulling body up, determined expression"
                ]
                return frames[min(frameIndex, frames.count - 1)]
            }
        }
    }
}

// MARK: - Generation Result

struct GeneratedFrame: Identifiable {
    let id = UUID()
    let action: PetGenerationConfig.PetAction
    let frameIndex: Int
    let image: NSImage?
    let imageData: Data?
    let prompt: String
    var isLoading: Bool = false
    var error: String?
}

// MARK: - OpenRouter Service

@Observable
class OpenRouterService {
    static let shared = OpenRouterService()

    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    private let model = "google/gemini-2.0-flash-exp:free"  // 使用免费的 Gemini 模型

    var apiKey: String = "" {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "openrouter_api_key")
        }
    }

    var isKeyValid: Bool = false
    var isGenerating: Bool = false
    var generationProgress: Double = 0
    var currentGeneratingAction: String = ""
    var generatedFrames: [GeneratedFrame] = []

    init() {
        apiKey = UserDefaults.standard.string(forKey: "openrouter_api_key") ?? ""
    }

    // MARK: - API Key Validation

    func validateAPIKey() async -> Bool {
        guard !apiKey.isEmpty else {
            isKeyValid = false
            return false
        }

        // 发送一个简单的测试请求
        let testRequest = OpenRouterRequest(
            model: model,
            messages: [
                OpenRouterRequest.Message(
                    role: "user",
                    content: [
                        OpenRouterRequest.ContentPart(type: "text", text: "Hello", imageUrl: nil)
                    ]
                )
            ],
            maxTokens: 10
        )

        do {
            let _ = try await sendRequest(testRequest)
            isKeyValid = true
            return true
        } catch {
            isKeyValid = false
            return false
        }
    }

    // MARK: - Generation

    func generatePetFrames(config: PetGenerationConfig) async throws {
        guard !apiKey.isEmpty else {
            throw GenerationError.noAPIKey
        }

        isGenerating = true
        generationProgress = 0
        generatedFrames = []

        defer {
            isGenerating = false
        }

        let totalFrames = config.actions.reduce(0) { $0 + $1.frameCount }
        var completedFrames = 0

        for action in config.actions {
            for frameIndex in 0..<action.frameCount {
                currentGeneratingAction = "\(action.displayName) (\(frameIndex + 1)/\(action.frameCount))"

                let prompt = buildPrompt(
                    config: config,
                    action: action,
                    frameIndex: frameIndex
                )

                // 创建占位帧
                var frame = GeneratedFrame(
                    action: action,
                    frameIndex: frameIndex,
                    image: nil,
                    imageData: nil,
                    prompt: prompt,
                    isLoading: true
                )
                generatedFrames.append(frame)

                do {
                    // 由于 Nano Banana Pro 是图像生成模型，这里使用文本描述生成
                    // 实际集成时可能需要使用不同的 API 端点
                    let response = try await generateFrameDescription(prompt: prompt)

                    // 更新帧状态（这里暂时只保存描述，实际应该是图像）
                    if let index = generatedFrames.firstIndex(where: { $0.id == frame.id }) {
                        generatedFrames[index].isLoading = false
                        // 在实际实现中，这里应该解析返回的图像数据
                    }
                } catch {
                    if let index = generatedFrames.firstIndex(where: { $0.id == frame.id }) {
                        generatedFrames[index].isLoading = false
                        generatedFrames[index].error = error.localizedDescription
                    }
                }

                completedFrames += 1
                generationProgress = Double(completedFrames) / Double(totalFrames)

                // 添加延迟以避免 rate limiting
                try await Task.sleep(nanoseconds: 500_000_000)  // 0.5秒
            }
        }
    }

    private func buildPrompt(
        config: PetGenerationConfig,
        action: PetGenerationConfig.PetAction,
        frameIndex: Int
    ) -> String {
        let actionDescription = action.framePrompt(frameIndex: frameIndex)
        let styleDescription = config.style.promptDescription

        var prompt = """
        Create a sprite frame for a desktop pet character named \(config.petName).
        Action: \(actionDescription)
        Style: \(styleDescription)
        Size: \(Int(config.size.width))x\(Int(config.size.height)) pixels
        Background: transparent
        Requirements: centered composition, full body visible, consistent proportions, cute and expressive
        """

        if let customPrompt = config.customPrompt, !customPrompt.isEmpty {
            prompt += "\nAdditional details: \(customPrompt)"
        }

        return prompt
    }

    private func generateFrameDescription(prompt: String) async throws -> String {
        let request = OpenRouterRequest(
            model: model,
            messages: [
                OpenRouterRequest.Message(
                    role: "user",
                    content: [
                        OpenRouterRequest.ContentPart(
                            type: "text",
                            text: "Describe in detail how this sprite frame would look: \(prompt)",
                            imageUrl: nil
                        )
                    ]
                )
            ],
            maxTokens: 500
        )

        let response = try await sendRequest(request)

        if let error = response.error {
            throw GenerationError.apiError(error.message)
        }

        return response.choices?.first?.message.content ?? ""
    }

    // MARK: - Network

    private func sendRequest(_ request: OpenRouterRequest) async throws -> OpenRouterResponse {
        guard let url = URL(string: baseURL) else {
            throw GenerationError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("Nano Pet", forHTTPHeaderField: "HTTP-Referer")
        urlRequest.setValue("Nano Pet macOS App", forHTTPHeaderField: "X-Title")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GenerationError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw GenerationError.unauthorized
        }

        if httpResponse.statusCode != 200 {
            throw GenerationError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(OpenRouterResponse.self, from: data)
    }

    // MARK: - Errors

    enum GenerationError: LocalizedError {
        case noAPIKey
        case invalidURL
        case invalidResponse
        case unauthorized
        case httpError(Int)
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "请先设置 OpenRouter API Key"
            case .invalidURL:
                return "无效的 API URL"
            case .invalidResponse:
                return "无效的服务器响应"
            case .unauthorized:
                return "API Key 无效或已过期"
            case .httpError(let code):
                return "HTTP 错误: \(code)"
            case .apiError(let message):
                return "API 错误: \(message)"
            }
        }
    }
}
