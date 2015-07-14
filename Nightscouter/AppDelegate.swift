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
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        // Load any saved meals, otherwise load sample data.
        if let savedSites = loadSites() {
            sites += savedSites
        } else {
            // Load the sample data.
            loadSampleSites()
        }
        setupNotificationSettings()

        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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
            
            nsApi.fetchServerConfigurationData({ (configuration, errorCode) -> Void in
                nsApi.fetchDataForWatchEntry({ (watchEntry, errorCode) -> Void in
                    // Get back on the main queue to update the user interface
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        site.configuration = configuration
                        site.watchEntry = watchEntry
                        // TODO:// Add some bg threshold checks here.
                        if site.watchEntry?.bgdelta != 0 {
                            self.scheduleLocalNotification(site)
                        }
                        if (site.watchEntry?.date.timeIntervalSinceNow < -(60 * 5)) {
                            completionHandler(.NoData)
                        } else {
                            completionHandler(.NewData)
                        }
//                        completionHandler(.Failed)
                    })
                })
            })
        }
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        println("Received a local notification payload: \(notification)")

        let dict = notification.userInfo
        
//        let site = find(sites, dict["site"])

//        println(dict)
//        application.applicationIconBadgeNumber = notification.applicationIconBadgeNumber - 1;
    }
    
    func scheduleLocalNotification(site: Site) {
        
        println("scheduleLocalNotification")
        
        let watch: WatchEntry! = site.watchEntry!
        let dateFor = NSDateFormatter()
        dateFor.timeStyle = .ShortStyle
        dateFor.dateStyle = .ShortStyle
        dateFor.doesRelativeDateFormatting = true
        
        var localNotification = UILocalNotification()
        localNotification.fireDate = NSDate()
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.category = "Nightscout_Category"
//        localNotification.applicationIconBadgeNumber = 1;
        
        localNotification.userInfo = NSDictionary(object: site.uuid!, forKey: "site") as [NSObject : AnyObject]
        
        localNotification.alertBody = "As of \(dateFor.stringFromDate(watch.date)), nighscout saw a bg of \(watch.sgv!.sgvString) with the delta of \(watch.bgdelta) \(watch.sgv!.direction.rawValue)"
        localNotification.alertAction = "View Site"
        
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

