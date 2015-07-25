//
//  AppDelegate.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var sites: [Site] {
        return AppDataManager.sharedInstance.sites
    }
    
    var timer: NSTimer?
    
    // MARK: AppDelegate Lifecycle
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        println(">>> Entering \(__FUNCTION__) <<<")
        // Override point for customization after application launch.
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        setupNotificationSettings() // Need to move this to when the user adds a server valid to the array.
        
        themeApp()
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        println(">>> Entering \(__FUNCTION__) <<<")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        self.timer?.invalidate()
        
        saveSites()
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        println(">>> Entering \(__FUNCTION__) <<<")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        saveSites()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        println(">>> Entering \(__FUNCTION__) <<<")
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        println(">>> Entering \(__FUNCTION__) <<<")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        application.idleTimerDisabled = AppDataManager.sharedInstance.shouldDisableIdleTimer

        updateDataNotification(nil)
    }
    
    func applicationWillTerminate(application: UIApplication) {
        println(">>> Entering \(__FUNCTION__) <<<")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        saveSites()
    }
    
    // MARK: Background Fetch
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        println(">>> Entering \(__FUNCTION__) <<<")
        for site in sites {
            // Get settings for a given site.
            let nsApi = NightscoutAPIClient(url: site.url)
            nsApi.fetchServerConfiguration { (result) -> Void in
                switch (result) {
                case let .Error(error):
                    // display error message
                    println("error: \(error)")
                    completionHandler(.Failed)
                    return
                case let .Value(boxedConfiguration):
                    let configuration:ServerConfiguration = boxedConfiguration.value
                    nsApi.fetchDataForWatchEntry({ (watchEntry, errorCode) -> Void in
                        site.configuration = configuration
                        site.watchEntry = watchEntry
                        
                        // don't push a notification if the data is stale. Probably needs to be refactored.
                        let timeFrame = site.watchEntry?.date.timeIntervalSinceNow
                        let timeLimit =  -Constants.StandardTimeFrame.TenMinutesInSeconds
                        
                        if ( timeFrame < timeLimit) {
                            completionHandler(.NoData)
                            return
                        } else {
                            // TODO: Add some bg threshold checks here.
                            if site.watchEntry?.bgdelta != 0 {
                                self.scheduleLocalNotification(site)
                            }
                            completionHandler(.NewData)
                            return
                        }
                    })
                }
            }
        }
        println("For some reason no one else comleted the request for a background fetch, so I am")
        completionHandler(.Failed)
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        println("Received a local notification payload: \(notification)")
        
        if let userInfoDict : [NSObject : AnyObject] = notification.userInfo {
            if let uuidString = userInfoDict["uuid"] as? String {
                let uuid = NSUUID(UUIDString: uuidString)
                let site = sites.filter{ $0.uuid == uuid }.first
                println("User tapped on notification for site: \(site)")
                
                // Need to add code that would launch the approprate view.
            }
        }
    }
    
    // MARK: Custom Methods
    
    func createUpdateTimer() -> NSTimer {
        let localTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.NotableTime.StandardRefreshTime, target: self, selector: Selector("updateDataNotification:"), userInfo: nil, repeats: true)
        return localTimer
    }
    
    func themeApp() {
        window?.tintColor = NSAssetKit.predefinedNeutralColor
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "HelveticaNeue-Thin", size: 20.0) {
            
            let navBarColor: UIColor = NSAssetKit.darkNavColor
            UINavigationBar.appearance().barTintColor = navBarColor
            
            let navBarAttributesDictionary: [NSObject: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.whiteColor(),
                NSFontAttributeName: navBarFont
            ]
            UINavigationBar.appearance().titleTextAttributes = navBarAttributesDictionary
        }
    }
    
    func updateDataNotification(timer: NSTimer?) -> Void {
        println(">>> Entering \(__FUNCTION__) <<<")
        println("Posting \(Constants.Notification.DataIsStaleUpdateNow) Notification at \(NSDate())")
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name:Constants.Notification.DataIsStaleUpdateNow, object: self))
        
        if (self.timer == nil) {
            self.timer = createUpdateTimer()
        }
    }
    
    func scheduleLocalNotification(site: Site) {
        println(">>> Entering \(__FUNCTION__) <<<")
        
        if (site.allowNotifications == false) { return }
        
        println("Scheduling a notification for site: \(site.url)")
        
        // remove old notifications before posting new one.
        //        for notification in site.notifications {
        //            UIApplication.sharedApplication().cancelLocalNotification(notification)
        //        }
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        let dateFor = NSDateFormatter()
        dateFor.timeStyle = .ShortStyle
        dateFor.dateStyle = .ShortStyle
        dateFor.doesRelativeDateFormatting = true
        
        var localNotification = UILocalNotification()
        localNotification.fireDate = NSDate()
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.category = "Nightscout_Category"
        //        localNotification.applicationIconBadgeNumber = 1;
        
        localNotification.userInfo = NSDictionary(object: site.uuid.UUIDString, forKey: "uuid") as [NSObject : AnyObject]
        //        localNotification.alertAction = "View Site"
        
        if let config = site.configuration {
            if let defaults = config.defaults {
                localNotification.alertTitle = "Update for \(defaults.customTitle)"
                if let watch: WatchEntry = site.watchEntry {
                    localNotification.alertBody = "As of \(dateFor.stringFromDate(watch.date)), \(defaults.customTitle) saw a BG of \(watch.sgv!.sgvString) with a delta of \(watch.bgdelta.formattedForBGDelta) \(watch.sgv!.direction.description). Uploader battery: \(watch.batteryString)"
                }
            }
        }
        //        site.notifications.append(localNotification)
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    func setupNotificationSettings() {
        println(">>> Entering \(__FUNCTION__) <<<")
        // Specify the notification types.
        var notificationTypes: UIUserNotificationType = UIUserNotificationType.Alert | UIUserNotificationType.Sound | UIUserNotificationType.Badge
        
        // Register the notification settings.
        let newNotificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(newNotificationSettings)
    }
    
    
    // MARK: NSCoding
    func saveSites() -> Void {
        AppDataManager.sharedInstance.saveAppData()
    }
}