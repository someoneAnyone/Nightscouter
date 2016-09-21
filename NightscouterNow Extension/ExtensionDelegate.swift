//
//  ExtensionDelegate.swift
//  NightscouterNow Extension
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import NightscouterWatchOSKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    var timer: Timer?
    
    override init() {
        print(">>> Entering \(#function) in ExtensionDelegate) <<<")

        super.init()
    }
    
    func applicationDidFinishLaunching() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
    }
    
    func applicationDidBecomeActive() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        updateDataNotification(nil)
    }
    
    func applicationWillResignActive() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        
        self.timer?.invalidate()
        self.timer = nil
      
    }
    
    func createUpdateTimer() -> Timer {
        let localTimer = Timer.scheduledTimer(timeInterval: TimeInterval.FourMinutesInSeconds, target: self, selector: #selector(ExtensionDelegate.updateDataNotification(_:)), userInfo: nil, repeats: true)
        
        return localTimer
    }
    
    func updateDataNotification(_ timer: Timer?) -> Void {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        
        OperationQueue.main.addOperation { () -> Void in
            NotificationCenter.default.post(.init(name: .NightscoutDataStaleNotification))
        }
        
        if (self.timer == nil) {
            self.timer = createUpdateTimer()
        }
    }
}

