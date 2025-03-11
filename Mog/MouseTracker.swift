import Foundation
import AppKit
import SwiftUI

class MouseTracker: ObservableObject {
    @Published var lastStoredPosition: NSPoint?
    @Published var isAccessibilityEnabled = false
    
    private var mouseMovementTimer: Timer?
    private var lastMousePosition: NSPoint = .zero
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    
    init() {
        checkAccessibilityPermissions()
        setupMouseMonitoring()
        setupKeyboardShortcut()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func checkAccessibilityPermissions() {
        let checkOptions = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let isCurrentlyTrusted = AXIsProcessTrustedWithOptions(checkOptions as CFDictionary)
        
        isAccessibilityEnabled = isCurrentlyTrusted
        
        if !isCurrentlyTrusted {
            print("Requesting accessibility permissions...")
            
            if Bundle.main.bundlePath.contains(".app") {
                print("Running from a proper .app bundle")
            } else {
                print("Warning: Not running from a proper .app bundle, which may affect permissions dialog")
            }
            
            openAccessibilityPreferences()
            
            let promptOptions = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            let promptResult = AXIsProcessTrustedWithOptions(promptOptions as CFDictionary)
            print("Prompt result: \(promptResult)")
            
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                let currentStatus = AXIsProcessTrustedWithOptions(checkOptions as CFDictionary)
                print("Checking accessibility permission status: \(currentStatus)")
                
                if currentStatus {
                    self.isAccessibilityEnabled = true
                    timer.invalidate()
                    self.setupMouseMonitoring()
                }
            }
        }
    }
    
    private func openAccessibilityPreferences() {
        let prefUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url = prefUrl {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func setupMouseMonitoring() {
        mouseMovementTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isAccessibilityEnabled else { return }
            
            let currentPosition = self.getCurrentMousePosition()
            
            if self.lastMousePosition.equalTo(currentPosition) {
                if self.mouseMovementTimer?.timeInterval ?? 0 >= 1.0 {
                    self.storeCurrentMousePosition()
                    self.mouseMovementTimer?.invalidate()
                    self.setupMouseMonitoring()
                } else {
                    self.mouseMovementTimer?.invalidate()
                    self.mouseMovementTimer = Timer.scheduledTimer(withTimeInterval: (self.mouseMovementTimer?.timeInterval ?? 0) + 0.1, repeats: true) { [weak self] _ in
                        self?.checkMouseMovement()
                    }
                }
            } else {
                self.lastMousePosition = currentPosition
                self.mouseMovementTimer?.invalidate()
                self.setupMouseMonitoring()
            }
        }
    }
    
    private func checkMouseMovement() {
        let currentPosition = getCurrentMousePosition()
        
        if lastMousePosition.equalTo(currentPosition) {
            if mouseMovementTimer?.timeInterval ?? 0 >= 1.0 {
                storeCurrentMousePosition()
                mouseMovementTimer?.invalidate()
                setupMouseMonitoring()
            }
        } else {
            lastMousePosition = currentPosition
            mouseMovementTimer?.invalidate()
            setupMouseMonitoring()
        }
    }
    
    private func storeCurrentMousePosition() {
        lastStoredPosition = getCurrentMousePosition()
        print("Stored mouse position: \(String(describing: lastStoredPosition))")
    }
    
    private func getCurrentMousePosition() -> NSPoint {
        if let currentEvent = CGEvent(source: nil) {
            let position = currentEvent.location
            return NSPoint(x: position.x, y: position.y)
        } else {
            return NSEvent.mouseLocation
        }
    }
    
    private func setupKeyboardShortcut() {
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        if event.modifierFlags.contains([.command, .control]) && event.keyCode == 15 {
            resetMousePosition()
        }
    }
    
    func resetMousePosition() {
        guard isAccessibilityEnabled, let position = lastStoredPosition else {
            print("Cannot reset mouse position: either accessibility not enabled or no position stored")
            return
        }
        
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: position, mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
        print("Reset mouse to position: \(position)")
    }
    
    func stopMonitoring() {
        mouseMovementTimer?.invalidate()
        mouseMovementTimer = nil
        
        if let globalMonitor = globalEventMonitor {
            NSEvent.removeMonitor(globalMonitor)
            globalEventMonitor = nil
        }
        
        if let localMonitor = localEventMonitor {
            NSEvent.removeMonitor(localMonitor)
            localEventMonitor = nil
        }
    }
}