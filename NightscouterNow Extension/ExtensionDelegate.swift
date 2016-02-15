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
    
    override init() {
        WatchSessionManager.sharedManager.startSession()
    }

    func applicationDidFinishLaunching() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        // Perform any final initialization of your application.
        
        
        //WatchSessionManager.sharedManager.startSession()
        updateDataNotification(nil)
    }
    
    func applicationDidBecomeActive() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    }
 
    func applicationWillResignActive() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        WatchSessionManager.sharedManager.endSession()
        self.timer?.invalidate()
    
    }
    
    func createUpdateTimer() -> NSTimer {
        let localTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.NotableTime.StandardRefreshTime, target: self, selector: Selector("updateDataNotification:"), userInfo: nil, repeats: true)
        return localTimer
    }

    func updateDataNotification(timer: NSTimer?) -> Void {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
            print("Posting \(NightscoutAPIClientNotification.DataIsStaleUpdateNow) Notification at \(NSDate())")
        #endif
        
        dispatch_async(dispatch_get_main_queue()) {
            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: NightscoutAPIClientNotification.DataIsStaleUpdateNow, object: self))
        }
        
        if (self.timer == nil) {
            self.timer = createUpdateTimer()
        }
    }
}

