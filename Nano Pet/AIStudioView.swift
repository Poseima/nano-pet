//
//  AIStudioView.swift
//  Nano Pet
//
//  AI 素材工作室 - 使用 AI 生成宠物素材
//

import SwiftUI
import UniformTypeIdentifiers

struct AIStudioView: View {
    @State private var openRouterService = OpenRouterService.shared

    // 配置选项
    @State private var petName: String = "我的小宠物"
    @State private var selectedStyle: PetGenerationConfig.PetStyle = .pixel
    @State private var selectedSize: CGSize = CGSize(width: 128, height: 128)
    @State private var selectedActions: Set<PetGenerationConfig.PetAction> = [.idle, .walk, .jump, .sleep]
    @State private var customPrompt: String = ""
    @State private var referenceImage: NSImage?

    // UI 状态
    @State private var showingAPIKeySheet = false
    @State private var apiKeyInput: String = ""
    @State private var showingImagePicker = false
    @State private var previewAction: PetGenerationConfig.PetAction = .idle
    @State private var previewFrame: Int = 0
    @State private var isPreviewPlaying = false
    @State private var previewTimer: Timer?

    private let sizeOptions: [CGSize] = [
        CGSize(width: 64, height: 64),
        CGSize(width: 128, height: 128),
        CGSize(width: 256, height: 256)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar

            // 主内容
            HStack(spacing: 0) {
                // 左侧配置面板
                configPanel
                    .frame(width: 320)

                Divider()

                // 右侧预览区
                previewPanel
            }
        }
        .background(Color(hex: "#FFF8F0"))
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingAPIKeySheet) {
            apiKeySheet
        }
        .onAppear {
            apiKeyInput = openRouterService.apiKey
        }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack {
            Image(systemName: "paintbrush.fill")
                .foregroundColor(Color(hex: "#FFB5A7"))
            Text("AI 素材工作室")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            Spacer()

            // API Key 状态
            Button(action: { showingAPIKeySheet = true }) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(openRouterService.isKeyValid ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(openRouterService.isKeyValid ? "API 已连接" : "设置 API Key")
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white)
                .cornerRadius(15)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
    }

    // MARK: - Config Panel

    private var configPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 参考图上传
                referenceImageSection

                Divider()

                // 基本信息
                basicInfoSection

                Divider()

                // 风格选择
                styleSection

                Divider()

                // 动作选择
                actionSection

                Divider()

                // 高级设置
                advancedSection

                // 生成按钮
                generateButton
            }
            .padding(20)
        }
    }

    private var referenceImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("参考图")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#636E72"))

            if let image = referenceImage {
                ZStack(alignment: .topTrailing) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                        .cornerRadius(12)

                    Button(action: { referenceImage = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            } else {
                Button(action: selectReferenceImage) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "#B2BEC3"))
                        Text("点击上传参考图")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(Color(hex: "#B2BEC3"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#DFE6E9"), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本信息")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#636E72"))

            VStack(alignment: .leading, spacing: 8) {
                Text("宠物名称")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#636E72"))

                TextField("输入宠物名称", text: $petName)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("尺寸")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#636E72"))

                HStack(spacing: 8) {
                    ForEach(sizeOptions, id: \.width) { size in
                        Button(action: { selectedSize = size }) {
                            Text("\(Int(size.width))x\(Int(size.height))")
                                .font(.system(size: 11, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedSize == size ? Color(hex: "#FFB5A7") : Color.white)
                                )
                                .foregroundColor(selectedSize == size ? .white : Color(hex: "#2D3436"))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("风格")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#636E72"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(PetGenerationConfig.PetStyle.allCases, id: \.rawValue) { style in
                    Button(action: { selectedStyle = style }) {
                        VStack(spacing: 6) {
                            Image(systemName: styleIcon(for: style))
                                .font(.system(size: 24))
                            Text(style.displayName)
                                .font(.system(size: 12, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedStyle == style ? Color(hex: "#FFB5A7") : Color.white)
                        )
                        .foregroundColor(selectedStyle == style ? .white : Color(hex: "#2D3436"))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func styleIcon(for style: PetGenerationConfig.PetStyle) -> String {
        switch style {
        case .pixel: return "square.grid.3x3.fill"
        case .watercolor: return "paintbrush.pointed.fill"
        case .flat: return "rectangle.fill"
        case .anime: return "sparkles"
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("需要生成的动作")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#636E72"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(PetGenerationConfig.PetAction.allCases, id: \.rawValue) { action in
                    Button(action: { toggleAction(action) }) {
                        HStack {
                            Image(systemName: selectedActions.contains(action) ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedActions.contains(action) ? Color(hex: "#FFB5A7") : Color(hex: "#B2BEC3"))

                            Text(action.displayName)
                                .font(.system(size: 12, design: .rounded))

                            Spacer()

                            Text("\(action.frameCount)帧")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "#B2BEC3"))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func toggleAction(_ action: PetGenerationConfig.PetAction) {
        if selectedActions.contains(action) {
            selectedActions.remove(action)
        } else {
            selectedActions.insert(action)
        }
    }

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup("高级设置") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("自定义提示词补充")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#636E72"))

                    TextEditor(text: $customPrompt)
                        .font(.system(size: 12))
                        .frame(height: 60)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(Color(hex: "#636E72"))
        }
    }

    private var generateButton: some View {
        Button(action: startGeneration) {
            HStack {
                if openRouterService.isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(openRouterService.isGenerating ? "生成中..." : "开始生成")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: openRouterService.isGenerating ?
                        [Color.gray, Color.gray] :
                        [Color(hex: "#FFB5A7"), Color(hex: "#FF8C94")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(openRouterService.isGenerating || selectedActions.isEmpty)
        .padding(.top, 10)
    }

    // MARK: - Preview Panel

    private var previewPanel: some View {
        VStack(spacing: 20) {
            if openRouterService.isGenerating {
                generationProgressView
            } else if !openRouterService.generatedFrames.isEmpty {
                generatedFramesView
            } else {
                emptyPreviewView
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var generationProgressView: some View {
        VStack(spacing: 16) {
            // 进度条
            VStack(spacing: 8) {
                ProgressView(value: openRouterService.generationProgress)
                    .progressViewStyle(.linear)
                    .tint(Color(hex: "#FFB5A7"))

                Text("正在生成: \(openRouterService.currentGeneratingAction)")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Color(hex: "#636E72"))

                Text("\(Int(openRouterService.generationProgress * 100))%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#FFB5A7"))
            }

            // 已生成的帧预览
            if !openRouterService.generatedFrames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(openRouterService.generatedFrames) { frame in
                            framePreviewCard(frame)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var generatedFramesView: some View {
        VStack(spacing: 16) {
            // 动画预览区
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .frame(height: 200)

                if let currentFrame = getCurrentPreviewFrame() {
                    if currentFrame.isLoading {
                        ProgressView()
                    } else if let image = currentFrame.image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 160)
                    } else {
                        // 占位显示
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: "#DFE6E9"))
                            Text(currentFrame.action.displayName)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#636E72"))
                        }
                    }
                }
            }

            // 动作选择
            HStack(spacing: 8) {
                ForEach(Array(selectedActions).sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { action in
                    Button(action: {
                        previewAction = action
                        previewFrame = 0
                    }) {
                        Text(action.displayName)
                            .font(.system(size: 12, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(previewAction == action ? Color(hex: "#FFB5A7") : Color.white)
                            )
                            .foregroundColor(previewAction == action ? .white : Color(hex: "#2D3436"))
                    }
                    .buttonStyle(.plain)
                }
            }

            // 播放控制
            HStack(spacing: 16) {
                Button(action: togglePreviewPlayback) {
                    Image(systemName: isPreviewPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#FFB5A7"))
                }
                .buttonStyle(.plain)

                Text("帧 \(previewFrame + 1)/\(previewAction.frameCount)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "#636E72"))
            }

            Divider()

            // 帧列表
            Text("所有帧")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#636E72"))
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                    ForEach(openRouterService.generatedFrames) { frame in
                        framePreviewCard(frame)
                    }
                }
            }

            // 保存按钮
            Button(action: savePet) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("保存为新宠物")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "#00B894"))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }

    private func framePreviewCard(_ frame: GeneratedFrame) -> some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 70, height: 70)

                if frame.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                } else if let image = frame.image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                } else if frame.error != nil {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                } else {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            }

            Text("\(frame.action.displayName)\(frame.frameIndex + 1)")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#636E72"))
        }
    }

    private var emptyPreviewView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "#DFE6E9"))

            Text("配置选项后点击\"开始生成\"")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color(hex: "#B2BEC3"))

            Text("AI 将根据您的设置生成宠物动画帧")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(Color(hex: "#DFE6E9"))
        }
    }

    // MARK: - API Key Sheet

    private var apiKeySheet: some View {
        VStack(spacing: 20) {
            Text("设置 OpenRouter API Key")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            Text("获取 API Key: openrouter.ai")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#636E72"))

            SecureField("输入 API Key", text: $apiKeyInput)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(hex: "#F8F9FA"))
                .cornerRadius(8)
                .frame(width: 300)

            HStack(spacing: 12) {
                Button("取消") {
                    showingAPIKeySheet = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color(hex: "#DFE6E9"))
                .cornerRadius(8)

                Button("保存并验证") {
                    openRouterService.apiKey = apiKeyInput
                    Task {
                        await openRouterService.validateAPIKey()
                    }
                    showingAPIKeySheet = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color(hex: "#FFB5A7"))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(30)
        .background(Color.white)
    }

    // MARK: - Actions

    private func selectReferenceImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            referenceImage = NSImage(contentsOf: url)
        }
    }

    private func startGeneration() {
        let config = PetGenerationConfig(
            petName: petName,
            style: selectedStyle,
            size: selectedSize,
            actions: Array(selectedActions),
            referenceImage: referenceImage?.tiffRepresentation,
            customPrompt: customPrompt.isEmpty ? nil : customPrompt
        )

        Task {
            try? await openRouterService.generatePetFrames(config: config)
        }
    }

    private func getCurrentPreviewFrame() -> GeneratedFrame? {
        openRouterService.generatedFrames.first { frame in
            frame.action == previewAction && frame.frameIndex == previewFrame
        }
    }

    private func togglePreviewPlayback() {
        isPreviewPlaying.toggle()

        if isPreviewPlaying {
            previewTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
                previewFrame = (previewFrame + 1) % previewAction.frameCount
            }
        } else {
            previewTimer?.invalidate()
            previewTimer = nil
        }
    }

    private func savePet() {
        // TODO: 保存生成的宠物到素材包
        print("保存宠物: \(petName)")
    }
}

#Preview {
    AIStudioView()
}
