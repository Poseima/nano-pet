//
//  AssetImportView.swift
//  Nano Pet
//
//  素材包导入界面
//

import SwiftUI
import UniformTypeIdentifiers

struct AssetImportView: View {
    @State private var assetManager = AssetPackManager.shared
    @State private var showingFilePicker = false
    @State private var importError: String?
    @State private var showingError = false
    @State private var selectedPack: AssetPack?
    @State private var showingDeleteConfirm = false

    // Pet 列表
    @State private var downloadedPets: [String] = []
    @State private var selectedPetToDelete: String?
    @State private var showingPetDeleteConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar

            ScrollView {
                VStack(spacing: 20) {
                    // 已导入的角色列表
                    if !downloadedPets.isEmpty {
                        petListSection
                    }

                    // 原有素材包列表
                    if !assetManager.installedPacks.isEmpty {
                        assetPacksSection
                    }

                    // 空状态
                    if downloadedPets.isEmpty && assetManager.installedPacks.isEmpty {
                        emptyStateView
                    }
                }
                .padding(20)
            }

            // 导入进度
            if assetManager.isImporting {
                importProgressView
            }
        }
        .background(Color(hex: "#FFF8F0"))
        .frame(minWidth: 500, minHeight: 500)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.zip, .folder, UTType(filenameExtension: "dreampet") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert(L.assetImportError, isPresented: $showingError) {
            Button(L.commonOK, role: .cancel) {}
        } message: {
            Text(importError ?? L.assetUnknownError)
        }
        .alert(L.assetConfirmDelete, isPresented: $showingDeleteConfirm) {
            Button(L.commonCancel, role: .cancel) {}
            Button(L.commonDelete, role: .destructive) {
                if let pack = selectedPack {
                    deletePack(pack)
                }
            }
        } message: {
            Text(L.assetDeletePackConfirm(selectedPack?.name ?? ""))
        }
        .alert(L.assetConfirmDeleteCharacter, isPresented: $showingPetDeleteConfirm) {
            Button(L.commonCancel, role: .cancel) {}
            Button(L.commonDelete, role: .destructive) {
                if let name = selectedPetToDelete {
                    deletePet(name)
                }
            }
        } message: {
            Text(L.assetDeleteCharacterConfirm(selectedPetToDelete ?? ""))
        }
        .onAppear {
            refreshPetList()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.circle")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#B2BEC3"))

            Text(L.assetImportNoCharacters)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#636E72"))

            Text(L.assetImportClickToImport)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#B2BEC3"))

            Button(action: { showingFilePicker = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text(L.assetImportButton)
                }
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "#6C5CE7"))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(40)
    }

    // MARK: - Pet List Section

    private var petListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Color(hex: "#FDCB6E"))
                Text(L.assetImportedCharacters)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(downloadedPets.count) \(L.assetImportCount)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#636E72"))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                ForEach(downloadedPets, id: \.self) { name in
                    petCard(name)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }

    private func petCard(_ name: String) -> some View {
        let isCurrent = assetManager.currentPet == name

        return VStack(spacing: 8) {
            // 预览图
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isCurrent ? Color(hex: "#DFE6E9") : Color(hex: "#F8F9FA"))
                    .frame(height: 80)

                if let preview = assetManager.loadPetPreview(name) {
                    Image(nsImage: preview)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#B2BEC3"))
                }

                // 当前使用标记
                if isCurrent {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#00B894"))
                                .font(.system(size: 16))
                        }
                        Spacer()
                    }
                    .padding(6)
                }
            }

            // 名称
            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "#2D3436"))
                .lineLimit(1)

            // Action buttons
            HStack(spacing: 6) {
                Button(action: { usePet(name) }) {
                    Text(isCurrent ? L.commonInUse : L.commonUse)
                        .font(.system(size: 10, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(isCurrent ? Color(hex: "#00B894") : Color(hex: "#74B9FF"))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .disabled(isCurrent)

                Button(action: {
                    selectedPetToDelete = name
                    showingPetDeleteConfirm = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .padding(4)
                        .background(Color(hex: "#FF7675").opacity(0.1))
                        .foregroundColor(Color(hex: "#FF7675"))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrent ? Color(hex: "#00B894") : Color.clear, lineWidth: 2)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        )
    }

    // MARK: - Asset Packs Section (原有)

    private var assetPacksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(Color(hex: "#FFB5A7"))
                Text(L.assetImportedPacks)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 12) {
                ForEach(assetManager.installedPacks) { pack in
                    packCard(pack)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }

    // MARK: - Helper Methods

    private func refreshPetList() {
        downloadedPets = assetManager.listDownloadedPets()
    }

    private func usePet(_ name: String) {
        assetManager.switchPet(to: name)
    }

    private func deletePet(_ name: String) {
        do {
            try assetManager.deletePet(name)
            refreshPetList()
        } catch {
            importError = error.localizedDescription
            showingError = true
        }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack {
            Image(systemName: "folder.badge.plus")
                .foregroundColor(Color(hex: "#FFB5A7"))
            Text(L.assetImportTitle)
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            Spacer()

            Button(action: { showingFilePicker = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text(L.assetImportButton)
                }
                .font(.system(size: 13, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "#FFB5A7"))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
    }

    private func packCard(_ pack: AssetPack) -> some View {
        VStack(spacing: 12) {
            // 预览图
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(height: 120)

                if let previewPath = pack.previewImagePath {
                    let fullPath = getPackDirectory(pack).appendingPathComponent(previewPath)
                    if let image = NSImage(contentsOf: fullPath) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 100)
                    } else {
                        placeholderImage
                    }
                } else {
                    placeholderImage
                }
            }

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(pack.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#2D3436"))
                    .lineLimit(1)

                HStack {
                    Text(pack.style)
                        .font(.system(size: 11))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#DFE6E9"))
                        .cornerRadius(4)

                    Text("\(Int(pack.size.width))x\(Int(pack.size.height))")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#636E72"))

                    Spacer()
                }

                Text("\(pack.animations.count) \(L.assetAnimations)")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#B2BEC3"))
            }

            // Action buttons
            HStack(spacing: 8) {
                Button(action: { usePack(pack) }) {
                    Text(L.commonUse)
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#00B894"))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: {
                    selectedPack = pack
                    showingDeleteConfirm = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .padding(6)
                        .background(Color(hex: "#FF7675").opacity(0.1))
                        .foregroundColor(Color(hex: "#FF7675"))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#F8F9FA"))
        )
    }

    private var placeholderImage: some View {
        Image(systemName: "photo")
            .font(.system(size: 32))
            .foregroundColor(Color(hex: "#DFE6E9"))
    }

    // MARK: - Import Progress

    private var importProgressView: some View {
        VStack(spacing: 12) {
            ProgressView(value: assetManager.importProgress)
                .progressViewStyle(.linear)
                .tint(Color(hex: "#FFB5A7"))

            Text(assetManager.importStatus)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(Color(hex: "#636E72"))
        }
        .padding(20)
        .background(Color.white)
    }

    // MARK: - Helper Methods

    private func getPackDirectory(_ pack: AssetPack) -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("DreamPet/AssetPacks/\(pack.id.uuidString)")
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            Task {
                do {
                    _ = try await assetManager.importAssetPack(from: url)
                    await MainActor.run {
                        refreshPetList()
                    }
                } catch {
                    await MainActor.run {
                        importError = error.localizedDescription
                        showingError = true
                    }
                }
            }

        case .failure(let error):
            importError = error.localizedDescription
            showingError = true
        }
    }

    private func usePack(_ pack: AssetPack) {
        // TODO: 切换当前使用的素材包
        print("使用素材包: \(pack.name)")
    }

    private func deletePack(_ pack: AssetPack) {
        do {
            try assetManager.deletePack(pack)
        } catch {
            importError = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    AssetImportView()
}
