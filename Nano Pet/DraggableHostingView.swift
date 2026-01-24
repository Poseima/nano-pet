//
//  DraggableHostingView.swift
//  Nano Pet
//
//  Custom NSHostingView that properly handles mouse events for borderless windows.
//  SwiftUI DragGesture on borderless transparent windows is unreliable - this provides
//  direct NSResponder-level mouse event handling.
//

import AppKit
import SwiftUI

// MARK: - Drag Event Delegate Protocol

/// Protocol for handling drag events from DraggableHostingView
protocol DragEventDelegate: AnyObject {
    func dragStarted(at point: NSPoint)
    func dragMoved(to point: NSPoint)
    func dragEnded(at point: NSPoint)
    func tapOccurred(at point: NSPoint)
}

// MARK: - Context Menu Delegate Protocol

/// Protocol for handling context menu actions from DraggableHostingView
protocol ContextMenuDelegate: AnyObject {
    // Spawning
    func spawnAnotherRequested()
    func divideRequested()
    func pullupRequested()

    // Movement
    func walkRequested()
    func jumpRequested()
    func climbRequested()
    func teleportRequested()
    func windowHoldRequested()

    // Resting
    func sitRequested()
    func lieDownRequested()
    func lookAroundRequested()

    // Special
    func sitLookUpRequested()
    func sitStretchRequested()
    func dangleRequested()

    // Routines
    func morningStretchRequested()
    func exerciseRequested()
    func foragingRequested()
    func napRequested()
    func sunbathingRequested()
    func deepSleepRequested()
    func nightPatrolRequested()

    // Remove
    func removeRequested()
    func removeAllRequested()
}

// MARK: - Draggable Hosting View

/// Custom NSHostingView that captures mouse events for borderless transparent windows
class DraggableHostingView<Content: View>: NSHostingView<Content>, NSMenuDelegate {

    /// Delegate to receive drag events
    weak var dragDelegate: DragEventDelegate?

    /// Delegate to receive context menu actions
    weak var contextMenuDelegate: ContextMenuDelegate?

    /// Whether we're currently tracking a drag operation
    private var isTracking = false

    /// Location where mouse down occurred (for tap detection)
    private var mouseDownLocation: NSPoint?

    /// Time when mouse down occurred (for tap detection)
    private var mouseDownTime: Date?

    /// Tracking area for mouse events
    private var trackingArea: NSTrackingArea?

    /// Threshold for distinguishing tap from drag (in pixels)
    private let tapThreshold: CGFloat = 5.0

    /// Maximum duration for a tap (in seconds)
    private let tapMaxDuration: TimeInterval = 0.3

    /// Whether context menu is currently showing
    private var isShowingContextMenu = false

    // MARK: - Tracking Area Setup

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        // Remove existing tracking area
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }

        // Create new tracking area covering entire view
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [
                .activeAlways,
                .mouseEnteredAndExited,
                .mouseMoved,
                .inVisibleRect
            ],
            owner: self,
            userInfo: nil
        )

        if let area = trackingArea {
            addTrackingArea(area)
        }
    }

    // MARK: - Mouse Event Handling

    override func mouseDown(with event: NSEvent) {
        isTracking = true
        mouseDownLocation = event.locationInWindow
        mouseDownTime = Date()

        // Notify delegate of drag start
        let globalPoint = NSEvent.mouseLocation
        dragDelegate?.dragStarted(at: globalPoint)
    }

    override func mouseDragged(with event: NSEvent) {
        guard isTracking else { return }

        // Notify delegate of drag movement using global cursor position
        let globalPoint = NSEvent.mouseLocation
        dragDelegate?.dragMoved(to: globalPoint)
    }

    override func mouseUp(with event: NSEvent) {
        guard isTracking else { return }
        isTracking = false

        let currentLocation = event.locationInWindow
        let globalPoint = NSEvent.mouseLocation

        // Check if this was a tap (small movement, short duration)
        var wasTap = false
        if let downLocation = mouseDownLocation,
           let downTime = mouseDownTime {
            let distance = hypot(currentLocation.x - downLocation.x, currentLocation.y - downLocation.y)
            let duration = Date().timeIntervalSince(downTime)

            if distance < tapThreshold && duration < tapMaxDuration {
                wasTap = true
                dragDelegate?.tapOccurred(at: globalPoint)
            }
        }

        // Always notify drag ended
        dragDelegate?.dragEnded(at: globalPoint)

        // Reset tracking state
        mouseDownLocation = nil
        mouseDownTime = nil
    }

    // MARK: - Hit Testing

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Don't intercept hits when a context menu is showing
        if isShowingContextMenu {
            return super.hitTest(point)
        }
        // Accept hits anywhere within our bounds, even on transparent pixels
        // This is critical for borderless transparent windows
        if bounds.contains(point) {
            return self
        }
        return nil
    }

    // MARK: - First Responder

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        // Accept clicks even when window is not focused
        return true
    }

    // MARK: - Right-Click Context Menu

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false

        // === Breeding Submenu ===
        let breedingMenu = NSMenu()
        breedingMenu.autoenablesItems = false

        addMenuItem(to: breedingMenu, title: "Another One!", action: #selector(spawnAnother))
        addMenuItem(to: breedingMenu, title: "Divide", action: #selector(triggerDivide))
        addMenuItem(to: breedingMenu, title: "Pullup", action: #selector(triggerPullup))

        let breedingItem = NSMenuItem(title: "🥚 Breeding", action: nil, keyEquivalent: "")
        breedingItem.submenu = breedingMenu
        menu.addItem(breedingItem)

        // === Movement Submenu ===
        let movementMenu = NSMenu()
        movementMenu.autoenablesItems = false

        addMenuItem(to: movementMenu, title: "Walk", action: #selector(triggerWalk))
        addMenuItem(to: movementMenu, title: "Jump", action: #selector(triggerJump))
        addMenuItem(to: movementMenu, title: "Climb Wall", action: #selector(triggerClimb))
        addMenuItem(to: movementMenu, title: "Dangle", action: #selector(triggerDangle))
        addMenuItem(to: movementMenu, title: "Window Hold", action: #selector(triggerWindowHold))
        movementMenu.addItem(NSMenuItem.separator())
        addMenuItem(to: movementMenu, title: "✨ Teleport to Window", action: #selector(triggerTeleport))

        let movementItem = NSMenuItem(title: "🏃 Movement", action: nil, keyEquivalent: "")
        movementItem.submenu = movementMenu
        menu.addItem(movementItem)

        // === Resting Submenu ===
        let restingMenu = NSMenu()
        restingMenu.autoenablesItems = false

        addMenuItem(to: restingMenu, title: "Sit", action: #selector(triggerSit))
        addMenuItem(to: restingMenu, title: "Lie Down", action: #selector(triggerLieDown))
        addMenuItem(to: restingMenu, title: "Look Around", action: #selector(triggerLookAround))
        addMenuItem(to: restingMenu, title: "Look Up", action: #selector(triggerSitLookUp))
        addMenuItem(to: restingMenu, title: "Stretch", action: #selector(triggerSitStretch))

        let restingItem = NSMenuItem(title: "😴 Resting", action: nil, keyEquivalent: "")
        restingItem.submenu = restingMenu
        menu.addItem(restingItem)

        // === Routines Submenu ===
        let routinesMenu = NSMenu()
        routinesMenu.autoenablesItems = false

        addMenuItem(to: routinesMenu, title: "🌅 Morning Stretch", action: #selector(triggerMorningStretch))
        addMenuItem(to: routinesMenu, title: "🏋️ Exercise", action: #selector(triggerExercise))
        addMenuItem(to: routinesMenu, title: "🔍 Foraging", action: #selector(triggerForaging))
        addMenuItem(to: routinesMenu, title: "💤 Nap", action: #selector(triggerNap))
        addMenuItem(to: routinesMenu, title: "☀️ Sunbathing", action: #selector(triggerSunbathing))
        addMenuItem(to: routinesMenu, title: "🌙 Deep Sleep", action: #selector(triggerDeepSleep))
        addMenuItem(to: routinesMenu, title: "🦉 Night Patrol", action: #selector(triggerNightPatrol))

        let routinesItem = NSMenuItem(title: "📋 Routines", action: nil, keyEquivalent: "")
        routinesItem.submenu = routinesMenu
        menu.addItem(routinesItem)

        menu.addItem(NSMenuItem.separator())

        // === Remove Options ===
        addMenuItem(to: menu, title: "Bye Bye!", action: #selector(removePet))
        addMenuItem(to: menu, title: "Bye Bye Everyone!", action: #selector(removeAllPets))

        isShowingContextMenu = true
        menu.popUp(positioning: nil, at: event.locationInWindow, in: self)
    }

    /// Helper to add menu items
    private func addMenuItem(to menu: NSMenu, title: String, action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.isEnabled = true
        menu.addItem(item)
    }

    // MARK: - Menu Actions

    @objc func spawnAnother() {
        contextMenuDelegate?.spawnAnotherRequested()
    }

    @objc func triggerDivide() {
        contextMenuDelegate?.divideRequested()
    }

    @objc func triggerPullup() {
        contextMenuDelegate?.pullupRequested()
    }

    @objc func triggerWalk() {
        contextMenuDelegate?.walkRequested()
    }

    @objc func triggerJump() {
        contextMenuDelegate?.jumpRequested()
    }

    @objc func triggerClimb() {
        contextMenuDelegate?.climbRequested()
    }

    @objc func triggerDangle() {
        contextMenuDelegate?.dangleRequested()
    }

    @objc func triggerTeleport() {
        contextMenuDelegate?.teleportRequested()
    }

    @objc func triggerWindowHold() {
        contextMenuDelegate?.windowHoldRequested()
    }

    @objc func triggerSit() {
        contextMenuDelegate?.sitRequested()
    }

    @objc func triggerLieDown() {
        contextMenuDelegate?.lieDownRequested()
    }

    @objc func triggerLookAround() {
        contextMenuDelegate?.lookAroundRequested()
    }

    @objc func triggerSitLookUp() {
        contextMenuDelegate?.sitLookUpRequested()
    }

    @objc func triggerSitStretch() {
        contextMenuDelegate?.sitStretchRequested()
    }

    // MARK: - Routine Actions

    @objc func triggerMorningStretch() {
        contextMenuDelegate?.morningStretchRequested()
    }

    @objc func triggerExercise() {
        contextMenuDelegate?.exerciseRequested()
    }

    @objc func triggerForaging() {
        contextMenuDelegate?.foragingRequested()
    }

    @objc func triggerNap() {
        contextMenuDelegate?.napRequested()
    }

    @objc func triggerSunbathing() {
        contextMenuDelegate?.sunbathingRequested()
    }

    @objc func triggerDeepSleep() {
        contextMenuDelegate?.deepSleepRequested()
    }

    @objc func triggerNightPatrol() {
        contextMenuDelegate?.nightPatrolRequested()
    }

    @objc func removePet() {
        contextMenuDelegate?.removeRequested()
    }

    @objc func removeAllPets() {
        contextMenuDelegate?.removeAllRequested()
    }

    // MARK: - NSMenuDelegate

    func menuDidClose(_ menu: NSMenu) {
        isShowingContextMenu = false
    }
}
