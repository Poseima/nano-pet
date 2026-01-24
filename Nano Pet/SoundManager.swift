//
//  SoundManager.swift
//  Nano Pet
//
//  Audio playback system for pet sounds
//

import Foundation
import AVFoundation
import AppKit

// MARK: - Sound Manager

/// Manages audio playback for pet sounds
class SoundManager {
    static let shared = SoundManager()

    /// Whether sounds are enabled (synced with AppSettings)
    var isEnabled: Bool {
        AppSettings.shared.enableSounds
    }

    /// Volume level (synced with AppSettings)
    var volume: Float {
        Float(AppSettings.shared.soundVolume)
    }

    /// Audio players for each pet
    private var audioPlayers: [String: [String: AVAudioPlayer]] = [:]

    /// Queue for managing concurrent access
    private let queue = DispatchQueue(label: "com.dreampet.soundmanager", qos: .userInitiated)

    /// Preloaded sounds for quick playback
    private var preloadedSounds: [String: [String: URL]] = [:]

    private init() {
        // Configure audio session for macOS
        setupAudioSession()
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        // macOS doesn't require AVAudioSession setup like iOS
        // Audio playback works directly
    }

    // MARK: - Sound Loading

    /// Preload sounds for a pet from config
    /// - Parameters:
    ///   - petName: Name of the pet
    ///   - sounds: Dictionary of sound name to file path
    func preloadSounds(for petName: String, sounds: [String: String]) {
        queue.async { [weak self] in
            guard let self = self else { return }

            var loadedSounds: [String: URL] = [:]

            for (soundName, filePath) in sounds {
                if let url = self.resolveSoundPath(filePath, for: petName) {
                    loadedSounds[soundName] = url
                    // Preload the audio player
                    self.createPlayer(for: url, pet: petName, sound: soundName)
                }
            }

            self.preloadedSounds[petName] = loadedSounds
            print("[SoundManager] Preloaded \(loadedSounds.count) sounds for \(petName)")
        }
    }

    /// Resolve sound file path relative to pet's asset directory
    private func resolveSoundPath(_ filePath: String, for petName: String) -> URL? {
        let assetPackManager = AssetPackManager.shared

        // Try relative to sprite path
        if let spritePath = assetPackManager.getSpritePath(for: petName) {
            let parentDir = spritePath.deletingLastPathComponent()

            // Try direct path
            let directPath = parentDir.appendingPathComponent(filePath)
            if FileManager.default.fileExists(atPath: directPath.path) {
                return directPath
            }

            // Try sounds subdirectory
            let soundsPath = parentDir.appendingPathComponent("sounds").appendingPathComponent(filePath)
            if FileManager.default.fileExists(atPath: soundsPath.path) {
                return soundsPath
            }
        }

        // Try bundle resources
        if let resourcePath = Bundle.main.resourcePath {
            let bundlePath = URL(fileURLWithPath: resourcePath)
                .appendingPathComponent("NanoPetAssets")
                .appendingPathComponent(petName)
                .appendingPathComponent(filePath)
            if FileManager.default.fileExists(atPath: bundlePath.path) {
                return bundlePath
            }
        }

        return nil
    }

    /// Create audio player for a sound
    private func createPlayer(for url: URL, pet: String, sound: String) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = volume

            if audioPlayers[pet] == nil {
                audioPlayers[pet] = [:]
            }
            audioPlayers[pet]?[sound] = player
        } catch {
            print("[SoundManager] Failed to create player for \(sound): \(error)")
        }
    }

    // MARK: - Sound Playback

    /// Play a sound for a pet
    /// - Parameters:
    ///   - soundName: Name of the sound (from config)
    ///   - petName: Name of the pet
    func playSound(_ soundName: String, for petName: String) {
        guard isEnabled else { return }

        queue.async { [weak self] in
            guard let self = self else { return }

            // Check for preloaded player
            if let player = self.audioPlayers[petName]?[soundName] {
                DispatchQueue.main.async {
                    player.volume = self.volume
                    player.currentTime = 0
                    player.play()
                }
                return
            }

            // Try to load on-demand
            if let sounds = self.preloadedSounds[petName],
               let url = sounds[soundName] {
                self.playSound(at: url, volume: self.volume)
                return
            }

            // Try to find sound file directly
            if let url = self.resolveSoundPath(soundName, for: petName) {
                self.playSound(at: url, volume: self.volume)
                return
            }

            // Try with common extensions
            for ext in ["wav", "mp3", "aiff", "m4a"] {
                if let url = self.resolveSoundPath("\(soundName).\(ext)", for: petName) {
                    self.playSound(at: url, volume: self.volume)
                    return
                }
            }

            print("[SoundManager] Sound not found: \(soundName) for \(petName)")
        }
    }

    /// Play sound at URL
    private func playSound(at url: URL, volume: Float) {
        DispatchQueue.main.async {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = volume
                player.play()

                // Clean up after playback
                DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
                    // Player will be deallocated
                }
            } catch {
                print("[SoundManager] Failed to play sound: \(error)")
            }
        }
    }

    // MARK: - Sound Management

    /// Stop all sounds for a pet
    func stopAllSounds(for petName: String) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let players = self.audioPlayers[petName] {
                    for player in players.values {
                        player.stop()
                    }
                }
            }
        }
    }

    /// Stop all sounds
    func stopAllSounds() {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                for players in self.audioPlayers.values {
                    for player in players.values {
                        player.stop()
                    }
                }
            }
        }
    }

    /// Update volume for all players
    func updateVolume() {
        let newVolume = volume

        for players in audioPlayers.values {
            for player in players.values {
                player.volume = newVolume
            }
        }
    }

    /// Clear cached sounds for a pet
    func clearCache(for petName: String) {
        queue.async { [weak self] in
            self?.audioPlayers.removeValue(forKey: petName)
            self?.preloadedSounds.removeValue(forKey: petName)
        }
    }

    /// Clear all cached sounds
    func clearAllCache() {
        queue.async { [weak self] in
            self?.audioPlayers.removeAll()
            self?.preloadedSounds.removeAll()
        }
    }
}

// MARK: - Convenience Methods

extension SoundManager {
    /// Play a generic sound (for brain callbacks)
    func play(_ soundName: String) {
        playSystemSound(soundName)
    }
}

// MARK: - System Sound Support

extension SoundManager {
    /// Play a system sound by name
    func playSystemSound(_ name: String) {
        guard isEnabled else { return }

        if let soundURL = Bundle.main.url(forResource: name, withExtension: nil) {
            playSound(at: soundURL, volume: volume)
        } else if let soundURL = Bundle.main.url(forResource: name, withExtension: "wav") {
            playSound(at: soundURL, volume: volume)
        } else if let soundURL = Bundle.main.url(forResource: name, withExtension: "mp3") {
            playSound(at: soundURL, volume: volume)
        }
    }

    /// Play macOS system sound
    func playMacOSSound(_ name: NSSound.Name) {
        guard isEnabled else { return }

        if let sound = NSSound(named: name) {
            sound.volume = volume
            sound.play()
        }
    }
}
