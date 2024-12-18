//
//  AppDelegate.swift
//  Clip2
//
//  Created by apple on 2024/12/4.
//

import AppKit
import SwiftUI
import KeyboardShortcuts

let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

class AppDelegate: NSObject, NSApplicationDelegate {
    @AppStorage("showOnDock") private var showOnDock: Bool = true
    @AppStorage("showMenubar") private var showMenubar: Bool = true
    
    func applicationWillFinishLaunching(_ aNotification: Notification) {
        if showOnDock { NSApp.setActivationPolicy(.regular) }
        if let button = statusBarItem.button {
            button.target = self
            button.image = NSImage(named: "statusIcon")
        }
        let menu = NSMenu()
        
        menu.addItem(withTitle: "About Clip²".local, action: #selector(about), keyEquivalent: "")
        menu.addItem(withTitle: "Settings…".local, action: #selector(settings), keyEquivalent: ",")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Check for Updates…".local, action: #selector(checkForUpdates), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit Clip²".local, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusBarItem.menu = menu
        statusBarItem.isVisible = showMenubar
        
        axPerm = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as NSDictionary)
        
        KeyboardShortcuts.onKeyDown(for: .cut) { ClipboardManager.shared.copyToClip2(cut: true) }
        KeyboardShortcuts.onKeyDown(for: .copy) { ClipboardManager.shared.copyToClip2() }
        KeyboardShortcuts.onKeyDown(for: .paste) { ClipboardManager.shared.pasteFromClip2() }
        
        tips("Clip² will use these hotkeys by default:\n\nControl + Command + X to Cut\nControl + Command + C to Copy\nControl + Command + V to Paste\n\nAnd you can change them in settings.", id: "clip2.hotkeys.tips")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        openSettingPanel()
        return true
    }
    
    @objc func about() {
        openAboutPanel()
    }
    
    @objc func settings() {
        openSettingPanel()
    }
    
    @objc func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

func openAboutPanel() {
    NSApp.activate(ignoringOtherApps: true)
    NSApp.orderFrontStandardAboutPanel()
}

func openSettingPanel() {
    NSApp.activate(ignoringOtherApps: true)
    if #available(macOS 14, *) {
        NSApp.mainMenu?.items.first?.submenu?.item(at: 3)?.performAction()
    }else if #available(macOS 13, *) {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    } else {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}

extension String {
    var local: String { return NSLocalizedString(self, comment: "") }
}

extension NSMenuItem {
    func performAction() {
        guard let menu else { return }
        menu.performActionForItem(at: menu.index(of: self))
    }
}

extension KeyboardShortcuts.Name {
    static let cut = Self("cut", default: .init(.x, modifiers: [.command, .control]))
    static let copy = Self("copy", default: .init(.c, modifiers: [.command, .control]))
    static let paste = Self("paste", default: .init(.v, modifiers: [.command, .control]))
}
