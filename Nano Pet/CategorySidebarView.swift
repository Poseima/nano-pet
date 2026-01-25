//
//  CategorySidebarView.swift
//  Nano Pet
//
//  Sidebar navigation for hierarchical pet categories
//

import SwiftUI

// MARK: - Category Sidebar View

struct CategorySidebarView: View {
    @Bindable var assetManager: AssetPackManager
    @Binding var selectedCategoryId: String?
    @Binding var selectedSuperCategoryId: String?
    @Binding var showFavorites: Bool
    @Binding var showRecent: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                // Quick Access Section
                quickAccessSection

                Divider()
                    .padding(.vertical, 8)

                // Categories Section
                categoriesSection
            }
            .padding(12)
        }
        .background(Color.white)
    }

    // MARK: - Quick Access Section

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sidebarItem(
                emoji: "📋",
                title: L.sidebarAll,
                count: assetManager.totalCharacterCount,
                isSelected: selectedCategoryId == nil && selectedSuperCategoryId == nil && !showFavorites && !showRecent
            ) {
                clearSelection()
            }

            sidebarItem(
                emoji: "⭐",
                title: L.nestFavorites,
                count: assetManager.favorites.count,
                isSelected: showFavorites
            ) {
                showFavorites = true
                showRecent = false
                selectedCategoryId = nil
                selectedSuperCategoryId = nil
            }

            sidebarItem(
                emoji: "🕐",
                title: L.nestRecent,
                count: assetManager.recentCharacters.count,
                isSelected: showRecent
            ) {
                showRecent = true
                showFavorites = false
                selectedCategoryId = nil
                selectedSuperCategoryId = nil
            }
        }
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L.sidebarCategories)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "#86868B"))
                .padding(.leading, 12)
                .padding(.bottom, 4)

            ForEach(assetManager.categories) { category in
                categoryItem(category)
            }
        }
    }

    // MARK: - Category Item

    private func categoryItem(_ category: PetCategory) -> some View {
        let isSelected = selectedCategoryId == category.id

        return Button(action: {
            selectedCategoryId = category.id
            selectedSuperCategoryId = nil
            showFavorites = false
            showRecent = false
        }) {
            HStack(spacing: 10) {
                // Show first pet's image instead of emoji
                if let firstChar = category.characters.first,
                   let preview = assetManager.loadPetPreview(firstChar) {
                    Image(nsImage: preview)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else {
                    Text(category.emoji)
                        .font(.system(size: 14))
                }

                Text(category.name)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : Color(hex: "#1D1D1F"))
                    .lineLimit(1)

                Spacer()

                Text("\(category.count)")
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color(hex: "#86868B"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.2) : Color(hex: "#F5F5F7"))
                    .cornerRadius(10)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#007AFF") : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Sidebar Item

    private func sidebarItem(
        emoji: String,
        title: String,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 14))

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : Color(hex: "#1D1D1F"))
                    .lineLimit(1)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color(hex: "#86868B"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.2) : Color(hex: "#F5F5F7"))
                    .cornerRadius(10)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#007AFF") : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper

    private func clearSelection() {
        selectedCategoryId = nil
        selectedSuperCategoryId = nil
        showFavorites = false
        showRecent = false
    }
}

#Preview {
    CategorySidebarView(
        assetManager: AssetPackManager.shared,
        selectedCategoryId: .constant(nil),
        selectedSuperCategoryId: .constant(nil),
        showFavorites: .constant(false),
        showRecent: .constant(false)
    )
    .frame(width: 220)
}
