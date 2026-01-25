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
    // Breeding
    func spawnAnotherRequested()
    func divideRequested()
    func pullupRequested()

    // Replace
    func randomReplaceRequested()

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

        let breedingItem = NSMenuItem(title: "Breeding", action: nil, keyEquivalent: "")
        breedingItem.submenu = breedingMenu
        menu.addItem(breedingItem)

        // === Random Replace ===
        addMenuItem(to: menu, title: "Random Replace", action: #selector(triggerRandomReplace))

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

    @objc func triggerRandomReplace() {
        contextMenuDelegate?.randomReplaceRequested()
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
