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
    
    override init() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
            print(">>> ExtensionDelegate <<<")
        #endif
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
                let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: urlTask.sessionIdentifier)
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
                    site.fetchDataFromNetwrok(completion: { (updatedSite, error) in
                        SitesDataSource.sharedInstance.updateSite(updatedSite)
                        group.leave()
                    })
                }
                group.leave()
                
                backgroundTask.setTaskCompleted()
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompleted()
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompleted()
            default:
                // make sure to complete unhandled task types
                task.setTaskCompleted()
            }
        }
    }

}

