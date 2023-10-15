//
//  AppDelegate.swift
//  Serifian
//
//  Created by Riccardo Persello on 08/10/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        let windowController = NSStoryboard.main?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("WelcomeWindowController")) as! WelcomeWindowController
        windowController.showWindow(self)
        
        return false
    }

}

