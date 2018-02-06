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
        wcBackgroundTasks.removeAll()
    }
    
    func applicationDidFinishLaunching() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        
        // Example scheduling of background task an hour in the future
        if #available(watchOSApplicationExtension 3.0, *) {
            WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: TimeInterval.OneHour), userInfo: nil) { (error: Error?) in
                if let error = error {
                    print("Error occured while scheduling background refresh: \(error.localizedDescription)")
                }
            }
        }
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
    @available(watchOSApplicationExtension 3.0, *)
    func testdsdf(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task : WKRefreshBackgroundTask in backgroundTasks {
            print("received background task: ", task)
            // only handle these while running in the background
            if (WKExtension.shared().applicationState == .background) {
                if task is WKApplicationRefreshBackgroundTask {
                    // this task is completed below, our app will then suspend while the download session runs
                    print("application task received, start URL session")
                    //scheduleURLSession()
                }
            }
            else if let urlTask = task as? WKURLSessionRefreshBackgroundTask {
                _ = URLSessionConfiguration.background(withIdentifier: urlTask.sessionIdentifier)
                //let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self, delegateQueue: nil)
                
               // print("Rejoining session ", backgroundSession)
            }
            // make sure to complete all tasks, even ones you don't handle
            task.setTaskCompleted()
        }
    }

    @available(watchOSApplicationExtension 3.0, *)
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                if (WKExtension.shared().applicationState == .background) {
                }

                let group = DispatchGroup()
                group.enter()
                for site in SitesDataSource.sharedInstance.sites {
                    group.enter()
                    site.fetchDataFromNetwork(useBackground: true, completion: { (updatedSite, error) in
                        SitesDataSource.sharedInstance.updateSite(updatedSite)
                        group.leave()
                    })
                }
                group.leave()
                
                backgroundTask.setTaskCompleted()
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.init(timeIntervalSinceNow: TimeInterval.ThirtyMinutes), userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                let group = DispatchGroup()
                group.enter()
                for site in SitesDataSource.sharedInstance.sites {
                    group.enter()
                    site.fetchDataFromNetwork(useBackground: true, completion: { (updatedSite, error) in
                        SitesDataSource.sharedInstance.updateSite(updatedSite)
                        group.leave()
                    })
                }
                group.leave()
                
                connectivityTask.setTaskCompleted()
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                let group = DispatchGroup()
                group.enter()
                for site in SitesDataSource.sharedInstance.sites {
                    group.enter()
                    site.fetchDataFromNetwork(useBackground: true, completion: { (updatedSite, error) in
                        SitesDataSource.sharedInstance.updateSite(updatedSite)
                        group.leave()
                    })
                }
                group.leave()
                
                urlSessionTask.setTaskCompleted()
            default:
                // make sure to complete unhandled task types
                let group = DispatchGroup()
                group.enter()
                for site in SitesDataSource.sharedInstance.sites {
                    group.enter()
                    site.fetchDataFromNetwork(useBackground: true, completion: { (updatedSite, error) in
                        SitesDataSource.sharedInstance.updateSite(updatedSite)
                        group.leave()
                    })
                }
                group.leave()
                
                task.setTaskCompleted()
            }
        }
    }

}

