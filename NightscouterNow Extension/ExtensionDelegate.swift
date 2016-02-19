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
    var timer: NSTimer?
    
    func applicationDidFinishLaunching() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        // Perform any final initialization of your application.
        
        WatchSessionManager.sharedManager.startSession()
            }
    
    func applicationDidBecomeActive() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        updateDataNotification(nil)
    }
 
    func applicationWillResignActive() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
     
        WatchSessionManager.sharedManager.saveData()
        self.timer?.invalidate()
    
    }
    
    func createUpdateTimer() -> NSTimer {
        let localTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.NotableTime.StandardRefreshTime, target: self, selector: Selector("updateDataNotification:"), userInfo: nil, repeats: true)
        return localTimer
    }

    func updateDataNotification(timer: NSTimer?) -> Void {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
            print("ExtensionDelegate:   Posting \(NightscoutAPIClientNotification.DataIsStaleUpdateNow) notification at \(NSDate())")
        #endif
        
        dispatch_async(dispatch_get_main_queue()) {
            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: NightscoutAPIClientNotification.DataIsStaleUpdateNow, object: self))
            ComplicationController.reloadComplications()
            WatchSessionManager.sharedManager.saveData()
        }
        
        if (self.timer == nil) {
            self.timer = createUpdateTimer()
        }
    }
}

