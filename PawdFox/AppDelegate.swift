//
//  AppDelegate.swift
//  PawdFox
//
//  Created by samuel.abreu on 10/01/2018.
//  Copyright © 2018 Personal Project. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for appWindow in sender.windows {
                appWindow.makeKeyAndOrderFront(self)
            }
        }
        return true
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        if let window = NSApplication.shared.windows.first?.contentViewController as? ViewController {
            window.openProfileIniPath(filename)
        }
        return true
    }
}

