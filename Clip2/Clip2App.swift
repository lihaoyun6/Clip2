//
//  Clip_App.swift
//  Clip2
//
//  Created by apple on 2024/12/4.
//

import SwiftUI

var firstLaunch = true
var axPerm = false

@main
struct Clip_App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
                .background(
                    WindowAccessor(
                        onWindowOpen: { w in
                            if let w = w {
                                w.titlebarSeparatorStyle = .none
                                guard let nsSplitView = findNSSplitVIew(view: w.contentView),
                                      let controller = nsSplitView.delegate as? NSSplitViewController else { return }
                                controller.splitViewItems.first?.canCollapse = false
                                controller.splitViewItems.first?.minimumThickness = 140
                                controller.splitViewItems.first?.maximumThickness = 140
                                w.orderFront(nil)
                            }
                        })
                )
        }.commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
