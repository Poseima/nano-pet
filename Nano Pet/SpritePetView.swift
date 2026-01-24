//
//  SpritePetView.swift
//  Nano Pet
//
//  Display-only sprite view - reads frame from mascot system
//

import SwiftUI
import AppKit

struct SpritePetView: View {
    let petName: String
    @Bindable var viewModel: PetViewModel

    // Use global cache for sprite frames
    private var allFrames: [Int: NSImage] {
        SpriteFrameCache.shared.getFrames(for: petName)
    }

    init(petName: String, viewModel: PetViewModel) {
        self.petName = petName
        self.viewModel = viewModel
    }

    /// Calculate opacity for teleport fade effect
    private var petOpacity: Double {
        switch viewModel.currentStateName {
        case "teleport_out":
            // Fade from 1.0 to 0.0 based on progress
            return max(0, 1.0 - viewModel.teleportProgress)
        case "teleport_in":
            // Fade from 0.0 to 1.0 based on progress
            return min(1.0, viewModel.teleportProgress)
        default:
            return 1.0
        }
    }

    var body: some View {
        ZStack {
            spriteImage
                .scaleEffect(x: viewModel.flipHorizontal ? -1 : 1, y: 1)
                .opacity(petOpacity)
        }
        .fixedSize()
        .contentShape(Rectangle())
        .drawingGroup()
        // Mouse events are now handled by DraggableHostingView at NSView level
        // This provides reliable drag/tap detection on borderless transparent windows
        .onAppear {
            // Preload frames
            SpriteFrameCache.shared.preload(petName: petName)
        }
    }

    @ViewBuilder
    private var spriteImage: some View {
        // Read frame directly from mascot via view model
        let frameNumber = viewModel.currentFrame
        if let frame = allFrames[frameNumber] {
            Image(nsImage: frame)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 128, height: 128)
        } else if let fallback = allFrames[1] {
            // Fallback to frame 1
            Image(nsImage: fallback)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 128, height: 128)
        } else {
            // Ultimate fallback
            Text("🐾")
                .font(.system(size: 60))
        }
    }
}

#Preview {
    SpritePetView(petName: "Agumon", viewModel: PetViewModel())
        .frame(width: 200, height: 200)
        .background(Color.gray.opacity(0.3))
}
