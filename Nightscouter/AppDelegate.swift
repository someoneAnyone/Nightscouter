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
    var sites: [Site] = [Site]()
    
    var timer: NSTimer?

    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        // Load any saved meals, otherwise load sample data.
        if let savedSites = loadSites() {
            sites += savedSites
            self.timer = NSTimer.scheduledTimerWithTimeInterval(Constants.NotableTime.StandardRefreshTime, target: self, selector: Selector("updateDataNotification:"), userInfo: nil, repeats: true)
        } else {
            // Load the sample data.
            loadSampleSites()
        }
        setupNotificationSettings()
        
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
        

        return true
    }
    
    func updateDataNotification(timer: NSTimer) -> Void {
        println("update data notification fired")
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name:Constants.Notification.DataIsStaleUpdateNow, object: self))

    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        saveSites()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        println("Handling background fetch")
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
                                // TODO:// Add some bg threshold checks here.
                                if site.watchEntry?.bgdelta != 0 {
                                    self.scheduleLocalNotification(site)
                                }
                                completionHandler(.NewData)
                                return
                            }
                        })
                }
            }
            
            
            println("For some reason no one else comleted the request for a background fetch, so I am")
        }
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        println("Received a local notification payload: \(notification)")
        
        if let userInfoDict : [NSObject : AnyObject] = notification.userInfo {
            if let uuidString = userInfoDict["uuid"] as? String {
                let uuid = NSUUID(UUIDString: uuidString)
                let site = sites.filter{ $0.uuid == uuid }.first
                println("User tapped on notification for site: \(site)")
            }
        }
        //        application.applicationIconBadgeNumber = notification.applicationIconBadgeNumber - 1;
    }
    
    func scheduleLocalNotification(site: Site) {
        println("scheduleLocalNotification")
        
        if (site.allowNotifications == false) { return }
        

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
        localNotification.alertAction = "View Site"
        
        if let config = site.configuration {
            if let defaults = config.defaults {
                localNotification.alertTitle = "Update for \(defaults.customTitle)"
                if let watch: WatchEntry = site.watchEntry {
                localNotification.alertBody = "As of \(dateFor.stringFromDate(watch.date)), \(defaults.customTitle) saw a BG of \(watch.sgv!.sgvString) with a delta of \(watch.bgdelta.formattedForBGDelta) \(watch.sgv!.direction.description). Uploader battery: \(watch.batteryString)"
                }
            }
        
        }
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    func setupNotificationSettings() {
        println("setupNotificationSettings")
        // Specify the notification types.
        var notificationTypes: UIUserNotificationType = UIUserNotificationType.Alert | UIUserNotificationType.Sound | UIUserNotificationType.Badge
        
        // Register the notification settings.
        let newNotificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(newNotificationSettings)
    }
    
    
    // MARK: NSCoding
    
    func saveSites() -> Void {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(sites, toFile: Site.ArchiveURL.path!)
        if !isSuccessfulSave {
            println("Failed to save sites...")
        }
    }
    
    func loadSites() -> [Site]? {
        let sites = NSKeyedUnarchiver.unarchiveObjectWithFile(Site.ArchiveURL.path!) as? [Site]
        return sites
    }
    
    func loadSampleSites() -> Void {
        // Create a site URL.
        /*
        let site1URL = NSURL(string: "https://nscgm.herokuapp.com")!
        // Create a site.
        let site1 = Site(url: site1URL, apiSecret: " ")!
        
        // Add it to the site Array
        sites = [site1]
        */
    }
    
}