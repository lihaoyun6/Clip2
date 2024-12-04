//
//  ClipboardManager.swift
//  Clip2
//
//  Created by apple on 2024/12/4.
//

import Carbon
import AppKit

class ClipboardManager {
    static let shared = ClipboardManager()
    private var pasteLock: Bool = false
    private var clip2: [NSPasteboardItem] = []
    private var retryCount: Int = 0
    
    func copyToClip2(cut: Bool = false) {
        let pasteboard = NSPasteboard.general
        var backupItems: [NSPasteboardItem] = []
        
        for item in pasteboard.pasteboardItems ?? [] {
            let newItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    newItem.setData(data, forType: type)
                }
            }
            backupItems.append(newItem)
        }
        
        let eventSource = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Command), keyDown: true)
        let cmdUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Command), keyDown: false)
        let cDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)
        let cUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)
        let xDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_X), keyDown: true)
        let xUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_X), keyDown: false)
        
        cmdDown?.flags = .maskCommand
        cDown?.flags = .maskCommand
        cmdDown?.flags = .maskCommand
        xDown?.flags = .maskCommand
        
        cmdDown?.post(tap: .cgAnnotatedSessionEventTap)
        if cut {
            print("cuting...")
            xDown?.post(tap: .cgAnnotatedSessionEventTap)
            xUp?.post(tap: .cgAnnotatedSessionEventTap)
        } else {
            print("copying...")
            cDown?.post(tap: .cgAnnotatedSessionEventTap)
            cUp?.post(tap: .cgAnnotatedSessionEventTap)
        }
        cmdUp?.post(tap: .cgAnnotatedSessionEventTap)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            setClip2(pasteboard, backup: backupItems)
        }
    }
    
    func setClip2(_ pasteboard: NSPasteboard, backup: [NSPasteboardItem]) {
        if isPasteboardEqualToBackup(pasteboard: pasteboard, backupItems: backup) && retryCount < 10 {
            print("Retrying...")
            retryCount += 1
            usleep(100000)
            setClip2(pasteboard, backup: backup)
        } else {
            retryCount = 0
            clip2.removeAll()
            for item in pasteboard.pasteboardItems ?? [] {
                let newItem = NSPasteboardItem()
                for type in item.types {
                    if let data = item.data(forType: type) {
                        newItem.setData(data, forType: type)
                    }
                }
                clip2.append(newItem)
            }
            pasteboard.clearContents()
            pasteboard.writeObjects(backup)
        }
    }
    
    func pasteFromClip2() {
        if clip2.isEmpty || pasteLock { return }
        
        let pasteboard = NSPasteboard.general
        var backupItems: [NSPasteboardItem] = []
        
        for item in pasteboard.pasteboardItems ?? [] {
            let newItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    newItem.setData(data, forType: type)
                }
            }
            backupItems.append(newItem)
        }
        
        pasteboard.clearContents()
        let newClip2 = clip2.map { oldItem -> NSPasteboardItem in
            let newItem = NSPasteboardItem()
            for type in oldItem.types {
                if let data = oldItem.data(forType: type) {
                    newItem.setData(data, forType: type)
                }
            }
            return newItem
        }
        pasteboard.writeObjects(newClip2)
        
        let eventSource = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Command), keyDown: true)
        let cmdUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Command), keyDown: false)
        let vDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let vUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        
        cmdDown?.flags = .maskCommand
        vDown?.flags = .maskCommand
        
        cmdDown?.post(tap: .cgAnnotatedSessionEventTap)
        vDown?.post(tap: .cgAnnotatedSessionEventTap)
        vUp?.post(tap: .cgAnnotatedSessionEventTap)
        cmdUp?.post(tap: .cgAnnotatedSessionEventTap)
        pasteLock = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pasteboard.clearContents()
            pasteboard.writeObjects(backupItems)
            self.pasteLock = false
        }
    }
    
    func isPasteboardEqualToBackup(pasteboard: NSPasteboard, backupItems: [NSPasteboardItem]) -> Bool {
        guard let currentItems = pasteboard.pasteboardItems else { return backupItems.isEmpty }
        guard currentItems.count == backupItems.count else { return false }
        
        for (currentItem, backupItem) in zip(currentItems, backupItems) {
            let currentTypes = Set(currentItem.types)
            let backupTypes = Set(backupItem.types)
            guard currentTypes == backupTypes else { return false }
            for type in currentTypes {
                let currentData = currentItem.data(forType: type)
                let backupData = backupItem.data(forType: type)
                if currentData != backupData {
                    return false
                }
            }
        }
        
        return true
    }
}
