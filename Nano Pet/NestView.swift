//
//  NestView.swift
//  Nano Pet
//
//  Hierarchical Pet Organization UI - Sidebar + Grid Layout
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - NestView

struct NestView: View {
    @State private var petManager = PetManager.shared
    @State private var assetManager = AssetPackManager.shared

    // Selection state
    @State private var selectedCategoryId: String? = nil
    @State private var selectedSuperCategoryId: String? = nil
    @State private var showFavorites: Bool = false
    @State private var showRecent: Bool = false

    // UI state
    @State private var searchText: String = ""
    @State private var isDropTargetActive: Bool = false
    @State private var draggedPet: String? = nil
    @State private var showSidebar: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Top navigation bar
            topBar

            // Main content with sidebar
            HStack(spacing: 0) {
                // Sidebar (collapsible)
                if showSidebar {
                    CategorySidebarView(
                        assetManager: assetManager,
                        selectedCategoryId: $selectedCategoryId,
                        selectedSuperCategoryId: $selectedSuperCategoryId,
                        showFavorites: $showFavorites,
                        showRecent: $showRecent
                    )
                    .frame(width: 200)
                    .transition(.move(edge: .leading))
                }

                // Divider
                if showSidebar {
                    Divider()
                }

                // Main grid area
                VStack(spacing: 0) {
                    // Active filter bar (if filtering)
                    if hasActiveFilter {
                        ActiveFilterBar(
                            category: selectedCategory,
                            showFavorites: showFavorites,
                            showRecent: showRecent,
                            assetManager: assetManager,
                            onClear: clearFilters
                        )
                        Divider()
                    }

                    // Category title
                    CategoryTitleBar(
                        title: currentTitle,
                        subtitle: "\(filteredCharacters.count) characters"
                    )

                    // Pet grid
                    if filteredCharacters.isEmpty {
                        emptyStateView
                    } else {
                        PetGridView(
                            characters: filteredCharacters,
                            assetManager: assetManager,
                            onSelect: { character in
                                deployPet(character)
                            },
                            onDrag: { character in
                                draggedPet = character
                            }
                        )
                    }

                    // Drop zone
                    dropZone

                    // Deployed pets section
                    deployedPetsSection
                }
            }
        }
        .background(Color(hex: "#F5F5F7"))
        .frame(minWidth: 500, minHeight: 400)
        .onReceive(NotificationCenter.default.publisher(for: .petChanged)) { _ in
            // Refresh if needed
        }
    }

    // MARK: - Computed Properties

    private var filteredCharacters: [String] {
        var result: [String]

        if showFavorites {
            result = Array(assetManager.favorites)
        } else if showRecent {
            result = assetManager.recentCharacters
        } else if let categoryId = selectedCategoryId {
            result = assetManager.getCharacters(for: categoryId)
        } else {
            result = assetManager.getAllCharacters()
        }

        // Apply search filter
        if !searchText.isEmpty {
            let search = searchText.lowercased()
            result = result.filter {
                $0.lowercased().contains(search) ||
                assetManager.getDisplayName(for: $0).lowercased().contains(search)
            }
        }

        return result.sorted()
    }

    private var hasActiveFilter: Bool {
        selectedCategoryId != nil || showFavorites || showRecent
    }

    private var selectedCategory: PetCategory? {
        guard let id = selectedCategoryId else { return nil }
        return assetManager.categories.first { $0.id == id }
    }

    private var currentTitle: String {
        if showFavorites {
            return L.nestFavorites
        } else if showRecent {
            return L.nestRecent
        } else if let cat = selectedCategory {
            return cat.name
        } else {
            return L.nestAllCharacters
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 16) {
            // Sidebar toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSidebar.toggle()
                }
            }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#86868B"))
            }
            .buttonStyle(.plain)

            // Logo
            HStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("Nano Pet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#1D1D1F"))
            }

            Spacer()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#86868B"))

                TextField(L.nestSearchPlaceholder, text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#C7C7CC"))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "#F5F5F7"))
            .cornerRadius(20)
            .frame(maxWidth: 280)

            Spacer()

            // Character count
            Text("\(assetManager.totalCharacterCount) \(L.nestCharacters)")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#86868B"))

            // Settings button
            Button(action: openSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#86868B"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white)
        .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "pawprint")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#C7C7CC"))

            Text(searchText.isEmpty ? L.nestNoCharactersFound : L.nestNoResultsFor(searchText))
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(hex: "#86868B"))

            if searchText.isEmpty {
                Text(L.nestImportMore)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#AEAEB2"))

                Button(action: openAssetImport) {
                    Text(L.nestImportCharacters)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#007AFF"))
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            } else {
                Button(action: { searchText = "" }) {
                    Text(L.nestClearSearch)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#007AFF"))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Drop Zone

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(isDropTargetActive ? Color(hex: "#007AFF").opacity(0.1) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isDropTargetActive ? Color(hex: "#007AFF") : Color(hex: "#E5E5EA"),
                            style: StrokeStyle(lineWidth: 2, dash: isDropTargetActive ? [] : [8])
                        )
                )
                .shadow(color: .black.opacity(0.04), radius: 8, y: 4)

            VStack(spacing: 8) {
                Image(systemName: isDropTargetActive ? "arrow.down.circle.fill" : "arrow.down.circle")
                    .font(.system(size: 28))
                    .foregroundColor(isDropTargetActive ? Color(hex: "#007AFF") : Color(hex: "#86868B"))

                Text(isDropTargetActive ? L.nestDropToDeployActive : L.nestDropToDeploy)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isDropTargetActive ? Color(hex: "#007AFF") : Color(hex: "#86868B"))
            }
        }
        .frame(height: 80)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onDrop(of: [.text], isTargeted: $isDropTargetActive) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - Deployed Pets Section

    private var deployedPetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#007AFF"))

                    Text(L.nestDesktopPets)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#1D1D1F"))

                    Text("(\(petManager.pets.count)/\(petManager.maxPets))")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#86868B"))
                }

                Spacer()

                if !petManager.pets.isEmpty {
                    Button(action: { petManager.removeAllPets() }) {
                        Text(L.nestRemoveAll)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#FF3B30"))
                    }
                    .buttonStyle(.plain)
                }
            }

            if petManager.pets.isEmpty {
                HStack {
                    Spacer()
                    Text(L.nestNoDesktopPets)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#86868B"))
                    Spacer()
                }
                .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(petManager.pets) { pet in
                            deployedPetCard(pet)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .shadow(color: .black.opacity(0.04), radius: 1, y: -1)
    }

    // MARK: - Deployed Pet Card

    private func deployedPetCard(_ pet: PetInstance) -> some View {
        HStack(spacing: 10) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#F5F5F7"))
                    .frame(width: 40, height: 40)

                if let img = assetManager.loadPetPreview(pet.petName) {
                    Image(nsImage: img)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                } else {
                    Text("🐾")
                        .font(.system(size: 18))
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(assetManager.getDisplayName(for: pet.petName))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#1D1D1F"))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Circle()
                        .fill(pet.isVisible ? Color(hex: "#34C759") : Color(hex: "#C7C7CC"))
                        .frame(width: 6, height: 6)

                    Text(pet.isVisible ? L.nestActive : L.nestHidden)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#86868B"))
                }
            }

            // Remove button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    petManager.removePet(pet)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#C7C7CC"))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color(hex: "#F5F5F7"))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func clearFilters() {
        selectedCategoryId = nil
        selectedSuperCategoryId = nil
        showFavorites = false
        showRecent = false
    }

    private func deployPet(_ character: String) {
        petManager.addPet(petName: character)
        assetManager.addToRecent(character)
        draggedPet = nil
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            if let name = object as? String {
                DispatchQueue.main.async {
                    deployPet(name)
                }
            }
        }
        return true
    }

    private func openSettings() {
        AppDelegate.shared?.openSettings()
    }

    private func openAssetImport() {
        AppDelegate.shared?.openAssetImport()
    }
}

#Preview {
    NestView()
}
