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
//        WatchSessionManager.sharedManager.startSession()
        
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
        
//        WatchSessionManager.sharedManager.saveData()
    }
    
    func createUpdateTimer() -> Timer {
        let localTimer = Timer.scheduledTimer(timeInterval: TimeInterval.FourMinutesInSeconds, target: self, selector: #selector(ExtensionDelegate.updateDataNotification(_:)), userInfo: nil, repeats: true)
        return localTimer
    }
    
    func updateDataNotification(_ timer: Timer?) -> Void {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        
        let date = Date()
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([.second], from: date)
        let delayedStart:Double=(Double)(10 - components.second!)
        let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64(delayedStart * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
//            print("ExtensionDelegate:   Posting \(NightscoutAPIClientNotification.DataIsStaleUpdateNow) notification at \(Date())")
            NotificationCenter.default.post(Notification(name: .NightscoutDataStaleNotification, object: self))
            
            if (self.timer == nil) {
                self.timer = self.createUpdateTimer()
            }
        })
    }
}

