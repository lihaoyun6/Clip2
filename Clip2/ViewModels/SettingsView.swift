//
//  SettingsView.swift
//  Clip2
//
//  Created by apple on 2024/12/4.
//

import SwiftUI
import KeyboardShortcuts
import ServiceManagement

struct SettingsView: View {
    @State private var selectedItem: String? = "General"
    
    var body: some View {
        NavigationView {
            List(selection: $selectedItem) {
                NavigationLink(destination: GeneralView(), tag: "General", selection: $selectedItem) {
                    Label("General", image: "gear")
                }
                NavigationLink(destination: HotkeyView(), tag: "Hotkey", selection: $selectedItem) {
                    Label("Hotkey", image: "hotkey")
                }
            }
            .listStyle(.sidebar)
            .padding(.top, 9)
        }
        .frame(width: 600, height: 400)
        .navigationTitle("Clip² Settings")
    }
}

struct GeneralView: View {
    @AppStorage("showOnDock") private var showOnDock: Bool = true
    @AppStorage("showMenubar") private var showMenubar: Bool = true
    
    @State private var launchAtLogin = false
    
    var body: some View {
        SForm {
            SGroupBox(label: "General") {
                if #available(macOS 13, *) {
                    SToggle("Launch at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            }catch{
                                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
                            }
                        }
                    SDivider()
                }
                SToggle("Show Clip² on Dock", isOn: $showOnDock)
                SDivider()
                SToggle("Show Clip² on Menu Bar", isOn: $showMenubar)
            }
            SGroupBox(label: "Update") {
                UpdaterSettingsView(updater: updaterController.updater)
            }
            VStack(spacing: 8) {
                HStack {
                    CheckForUpdatesView(updater: updaterController.updater)
                    if !showOnDock && !showMenubar {
                        Button("Quit Clip²") { NSApp.terminate(self) }
                    }
                }
                if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Clip² v\(appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear{ if #available(macOS 13, *) { launchAtLogin = (SMAppService.mainApp.status == .enabled) }}
        .onChange(of: showMenubar) { newValue in statusBarItem.isVisible = newValue }
        .onChange(of: showOnDock) { newValue in
            if !newValue { NSApp.setActivationPolicy(.accessory) } else { NSApp.setActivationPolicy(.regular) }
        }
    }
}

struct HotkeyView: View {
    var body: some View {
        SForm(spacing: 10) {
            SGroupBox(label: "Hotkey") {
                SItem(label: "Copy to Clip²") { KeyboardShortcuts.Recorder("", name: .copy) }
                SDivider()
                SItem(label: "Cut to Clip²"){ KeyboardShortcuts.Recorder("", name: .cut) }
                SDivider()
                SItem(label: "Paste from Clip²"){ KeyboardShortcuts.Recorder("", name: .paste) }
            }
        }
    }
}
