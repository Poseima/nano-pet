//
//  PetGridView.swift
//  Nano Pet
//
//  Grid view for displaying pet characters with hover effects
//

import SwiftUI

// MARK: - Pet Grid View

struct PetGridView: View {
    let characters: [String]
    let assetManager: AssetPackManager
    let onSelect: (String) -> Void
    let onDrag: (String) -> Void

    @State private var hoveredCharacter: String? = nil

    private let gridColumns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(characters, id: \.self) { character in
                    petCard(for: character)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Pet Card

    private func petCard(for character: String) -> some View {
        let isFavorite = assetManager.favorites.contains(character)
        let isHovered = hoveredCharacter == character
        let displayName = assetManager.getDisplayName(for: character)
        let category = assetManager.getCategory(for: character)

        return VStack(spacing: 4) {
            // Pet image - large, filling the card
            ZStack(alignment: .topTrailing) {
                if let preview = assetManager.loadPetPreview(character) {
                    Image(nsImage: preview)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 100, maxHeight: 100)
                        .offset(y: isHovered ? -4 : 0)
                } else {
                    Text("🐾")
                        .font(.system(size: 48))
                }

                // Favorite indicator
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                        .padding(4)
                }
            }
            .frame(height: 100)

            // Name
            Text(displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "#1D1D1F"))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 100, height: 32)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: isHovered ? Color(hex: "#007AFF").opacity(0.2) : .black.opacity(0.06),
                    radius: isHovered ? 12 : 6,
                    y: isHovered ? 6 : 3
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHovered ? Color(hex: "#007AFF") : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            hoveredCharacter = hovering ? character : nil
        }
        .onTapGesture {
            onSelect(character)
        }
        .onDrag {
            onDrag(character)
            return NSItemProvider(object: character as NSString)
        }
        .contextMenu {
            Button(action: { assetManager.toggleFavorite(character) }) {
                Label(
                    isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: isFavorite ? "star.slash" : "star"
                )
            }

            Divider()

            Button(action: { onSelect(character) }) {
                Label("Deploy to Desktop", systemImage: "arrow.down.to.line")
            }
        }
    }
}

// MARK: - Active Filter Bar

struct ActiveFilterBar: View {
    let category: PetCategory?
    let showFavorites: Bool
    let showRecent: Bool
    let assetManager: AssetPackManager
    let onClear: () -> Void

    var body: some View {
        if let cat = category {
            categoryFilterBar(cat)
        } else if showFavorites {
            filterBar(emoji: "⭐", title: "Favorites")
        } else if showRecent {
            filterBar(emoji: "🕐", title: "Recent")
        }
    }

    private func categoryFilterBar(_ cat: PetCategory) -> some View {
        HStack {
            Text("Filtering:")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#86868B"))

            HStack(spacing: 6) {
                // Show first pet's image instead of emoji
                if let firstChar = cat.characters.first,
                   let preview = assetManager.loadPetPreview(firstChar) {
                    Image(nsImage: preview)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                } else {
                    Text(cat.emoji)
                }
                Text(cat.name)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(hex: "#007AFF"))
            .cornerRadius(14)

            Spacer()

            Button(action: onClear) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                    Text("Clear")
                        .font(.system(size: 13))
                }
                .foregroundColor(Color(hex: "#FF3B30"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#007AFF").opacity(0.05))
    }

    private func filterBar(emoji: String, title: String) -> some View {
        HStack {
            Text("Filtering:")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#86868B"))

            HStack(spacing: 6) {
                Text(emoji)
                Text(title)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(hex: "#007AFF"))
            .cornerRadius(14)

            Spacer()

            Button(action: onClear) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                    Text("Clear")
                        .font(.system(size: 13))
                }
                .foregroundColor(Color(hex: "#FF3B30"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#007AFF").opacity(0.05))
    }
}

// MARK: - Category Title Bar

struct CategoryTitleBar: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "#1D1D1F"))

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#86868B"))
                .padding(.leading, 8)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    PetGridView(
        characters: ["test-character-1", "test-character-2"],
        assetManager: AssetPackManager.shared,
        onSelect: { _ in },
        onDrag: { _ in }
    )
}
