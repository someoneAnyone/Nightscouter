//
//  ExtensionDelegate.swift
//  NightscouterNow Extension
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import NightscouterWatchOSKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    private var wcBackgroundTasks = [WKWatchConnectivityRefreshBackgroundTask]()
    
    override init() {
        
        super.init()
        
        #if DEBUG
            print(">>> Entering \(#function) <<<")
            print(">>> ExtensionDelegate <<<")
        #endif
        // WKWatchConnectivityRefreshBackgroundTask should be completed – Otherwise they will keep consuming
        // the background executing time and eventually causes an app crash.
        // The timing to complete the tasks is when the current WCSession turns to not .activated or
        // hasContentPending flipped to false (see completeBackgroundTasks), so KVO is set up here to observe
        // the changes if the two properties.
        //
        WCSession.default.addObserver(self, forKeyPath: "activationState", options: [], context: nil)
        WCSession.default.addObserver(self, forKeyPath: "hasContentPending", options: [], context: nil)
        
        // Create the session coordinator to activate the session asynchronously as early as possible.
        // In the case of being background launched with a task, this may save some background runtime budget.
        //
        _ = SitesDataSource.sharedInstance
    }
    
    // When the WCSession's activationState and hasContentPending flips, complete the background tasks.
    //
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async {
            self.completeBackgroundTasks()
        }
    }
    
    // Compelete the background tasks, and schedule a snapshot refresh.
    //
    func completeBackgroundTasks() {
        guard !wcBackgroundTasks.isEmpty else { return }
        
        let session = WCSession.default
        guard session.activationState == .activated && !session.hasContentPending else { return }
        
        wcBackgroundTasks.forEach { $0.setTaskCompleted() }
        
        if (WKExtension.shared().applicationState == .background) {
            SitesDataSource.sharedInstance.appIsInBackground = true
            for site in SitesDataSource.sharedInstance.sites {
                site.fetchDataFromNetwork(useBackground: true, completion: { (updatedSite, error) in
                    SitesDataSource.sharedInstance.updateSite(updatedSite)
                })
            }
        }
        
        // Use FileLogger to log the tasks for debug purpose. A real app may remove the log
        // to save the precious background time.
        //
        //  FileLogger.shared.append(line: "\(#function):\(wcBackgroundTasks) was completed!")
        
        // Schedule a snapshot refresh if the UI is updated by background tasks.
        //
        
        
        let date = Date(timeIntervalSinceNow: 1)
        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: date, userInfo: nil) { error in
            
            if let error = error {
                print("scheduleSnapshotRefresh error: \(error)!")
            }
        }
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: TimeInterval.OneHour), userInfo: nil) { (error: Error?) in
            if let error = error {
                print("Error occured while scheduling background refresh: \(error.localizedDescription)")
            }
        }
        
        wcBackgroundTasks.removeAll()
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
    }
    
    func applicationWillResignActive() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
    }
    
    // Be sure to complete all the tasks - otherwise they will keep consuming the background executing
    // time until the time is out of budget and the app is killed.
    //
    // WKWatchConnectivityRefreshBackgroundTask should be completed after the pending data is received
    // so retain the tasks first. The retained tasks will be completed at the following cases:
    // 1. hasContentPending flips to false, meaning all the pending data is received. Pending data means
    //    the data received by the device prior to the WCSession getting activated.
    //    More data might arrive, but it isn't pending when the session activated.
    // 2. The end of the handle method.
    //    This happens when hasContentPending can flip to false before the tasks are retained.
    //
    // If the tasks are completed before the WCSessionDelegate methods are called, the data will be delivered
    // the app is running next time, so no data lost.
    //
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            
            // Use FileLogger to log the tasks for debug purpose. A real app may remove the log
            // to save the precious background time.
            //
            if let wcTask = task as? WKWatchConnectivityRefreshBackgroundTask {
                wcBackgroundTasks.append(wcTask)
//                FileLogger.shared.append(line: "\(#function):\(wcTask.description) was appended!")
            }
            else {
                task.setTaskCompleted()
//                FileLogger.shared.append(line: "\(#function):\(task.description) was completed!")
            }
        }
        completeBackgroundTasks()
    }
}

