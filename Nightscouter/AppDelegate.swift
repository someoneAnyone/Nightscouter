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
        // println(">>> Entering \(__FUNCTION__) <<<")
        // Override point for customization after application launch.
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        application.applicationIconBadgeNumber = 0
        application.cancelAllLocalNotifications()
        
        setupNotificationSettings() // Need to move this to when the user adds a server valid to the array.
        
        themeApp()
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // println(">>> Entering \(__FUNCTION__) <<<")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        self.timer?.invalidate()
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // println(">>> Entering \(__FUNCTION__) <<<")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        saveSites()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // println(">>> Entering \(__FUNCTION__) <<<")
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // println(">>> Entering \(__FUNCTION__) <<<")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        // application.idleTimerDisabled = AppDataManager.sharedInstance.shouldDisableIdleTimer
        
        updateDataNotification(nil)
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // println(">>> Entering \(__FUNCTION__) <<<")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        saveSites()
    }
    
    // MARK: Background Fetch
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        // println(">>> Entering \(__FUNCTION__) <<<")
        
        for site in sites {
            // Get settings for a given site.
            let nsApi = NightscoutAPIClient(url: site.url)
            
            nsApi.fetchServerConfiguration { (result) -> Void in
                switch (result) {
                case let .Error(error):
                    // display error message
                    println("error: \(error)")
                    break
                case let .Value(boxedConfiguration):
                    let configuration:ServerConfiguration = boxedConfiguration.value
                    nsApi.fetchDataForWatchEntry({ (watchEntry, errorCode) -> Void in
                        site.configuration = configuration
                        site.watchEntry = watchEntry
                        
                        if let defaults = configuration.defaults {
                            // don't push a notification if the data is stale. Probably needs to be refactored.
                            let timeFrame = site.watchEntry?.date.timeIntervalSinceNow
                            let timeLimit = max(Constants.NotableTime.StaleDataTimeFrame, defaults.alarms.alarmTimeAgoWarnMins)
                            
                            if ( timeFrame < -timeLimit) {
                            } else {
                                // TODO: Add some bg threshold checks here.
                                if site.watchEntry?.bgdelta != 0 {
                                    self.scheduleLocalNotification(site)
                                }
                            }
                        }
                    })
                }
            }
        }
        
        // Always return NewData.
        // TODO: Refactor this so we can actually say with some accuracy that we did infact update with NewData or failed. It needs to take into account all the sites... one might fail but other might get new data... should return newdata at that point. If all fail (bad connection) then it should report .Fiailed.
        
        completionHandler(.NewData)
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        println(">>> Entering \(__FUNCTION__) <<<")
        println("Recieved URL: \(url) from sourceApplication: \(sourceApplication) annotation: \(annotation))")
        
        var schemes = AppDataManager.sharedInstance.supportedSchemes!
        if (!contains(schemes, url.scheme!)) { // If the incoming scheme is not contained within the array of supported schemes return false.
            return false
        }
        
        // We now have an acceptable scheme. Pass the URL to the deep linking handler.
        deepLinkToURL(url)
        
        return true
    }
    
    // MARK: Local Notifications
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        // println("Received a local notification payload: \(notification)")
        if let userInfoDict : [NSObject : AnyObject] = notification.userInfo {
            if let uuidString = userInfoDict[Site.PropertyKey.uuidKey] as? String {
                let uuid = NSUUID(UUIDString: uuidString) // Get the uuid from the notification.
                let site = sites.filter{ $0.uuid == uuid }.first // Use the uuid value to get the site object from the array.
                let siteIndex = find(sites, site!) // Use the site object to get its index position in the array.
                
                site?.notifications.removeAtIndex(find(site!.notifications, notification)!)
                AppDataManager.sharedInstance.updateSite(site!)
                AppDataManager.sharedInstance.currentSiteIndex = siteIndex!
                
                // println("User tapped on notification for site: \(site) at index \(siteIndex)")
                
                let url = NSURL(string: "nightscouter://link/\(UIStoryboard.StoryboardViewControllerIdentifier.SiteListPageViewController.rawValue)")
                if let site = (sites.filter{ $0.uuid == uuid }.first) { // Use the uuid value to get the site object from the array.
                    if let siteIndex = find(sites, site) { // Use the site object to get its index position in the array.
                        AppDataManager.sharedInstance.currentSiteIndex = siteIndex
                        if let notificationIndex  = find(site.notifications, notification) {
                            site.notifications.removeAtIndex(notificationIndex)
                            // println("User tapped on notification for site: \(site) at index \(siteIndex)")
                            
                            let url = NSURL(string: "nightscouter://link/\(UIStoryboard.StoryboardViewControllerIdentifier.SiteListPageViewController.rawValue)")
                            deepLinkToURL(url!)
                        }
                    }
                }
            } else {
                let url = NSURL(string: "nightscouter://link/\(UIStoryboard.StoryboardViewControllerIdentifier.SiteFormViewController.rawValue)")
                deepLinkToURL(url!)
            }
        }
    }
    
    // MARK: Remote Notifications
    /*
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    println(">>> Entering \(__FUNCTION__) <<<")
    println("userInfo: \(userInfo)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
    println(">>> Entering \(__FUNCTION__) <<<")
    println("userInfo: \(userInfo)")
    completionHandler(.NewData)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    println(">>> Entering \(__FUNCTION__) <<<")
    println("deviceToken: \(deviceToken)")
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    println(">>> Entering \(__FUNCTION__) <<<")
    println("\(error), \(error.localizedDescription)")
    }
    */
    
    // MARK: Custom Methods
    
    func deepLinkToURL(url: NSURL) {
        // Maybe this can be expanded to handle icomming messages from remote or local notifications.
        if let pathComponents = url.pathComponents {
            
            if let queryItems = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)?.queryItems {
                #if DEBUG
                    println("queryItems: \(queryItems)") // Not handling queries at that moment, but might want to.
                #endif
            }
            
            if let navController = self.window?.rootViewController as? UINavigationController { // Get the root view controller's navigation controller.
                navController.popToRootViewControllerAnimated(false) // Return to root viewcontroller without animation.
                let storyboard = self.window?.rootViewController?.storyboard // Grab the storyboard from the rootview.
                var viewControllers = navController.viewControllers as! [UIViewController] // Grab all the current view controllers in the stack.
                for storyboardID in pathComponents { // iterate through all the path components. Currently the app only has one level of deep linking.
                    if let stringID = storyboardID as? String { // Cast the AnyObject into a string.
                        if let stor = UIStoryboard.StoryboardViewControllerIdentifier(rawValue: stringID) { // Attempt to create a storyboard identifier out of the string.
                            let linkIsAllowed = contains(UIStoryboard.StoryboardViewControllerIdentifier.deepLinkableStoryboards, stor) // Check to see if this is an allowed viewcontroller.
                            if linkIsAllowed {
                                let newViewController = storyboard!.instantiateViewControllerWithIdentifier(stringID) as! UIViewController
                                
                                switch (stor) {
                                case .SiteListPageViewController:
                                    viewControllers.append(newViewController) // Create the view controller and append it to the navigation view controller stack
                                case .SiteFormViewController:
                                    navController.presentViewController(newViewController, animated: false, completion: { () -> Void in
                                        // ...
                                    })
                                default:
                                    viewControllers.append(newViewController) // Create the view controller and append it to the navigation view controller stack
                                }
                            }
                        }
                    }
                }
                navController.viewControllers = viewControllers // Apply the updated list of view controller to the current navigation controller.
            }
        }
    }
    
    func createUpdateTimer() -> NSTimer {
        let localTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.NotableTime.StandardRefreshTime, target: self, selector: Selector("updateDataNotification:"), userInfo: nil, repeats: true)
        return localTimer
    }
    
    func themeApp() {
        window?.tintColor = NSAssetKit.predefinedNeutralColor
        // Change the font and size of nav bar text.
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
        // println(">>> Entering \(__FUNCTION__) <<<")
        // println("Posting \(Constants.Notification.DataIsStaleUpdateNow) Notification at \(NSDate())")
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name:Constants.Notification.DataIsStaleUpdateNow, object: self))
        
        if (self.timer == nil) {
            self.timer = createUpdateTimer()
        }
    }
    
    func scheduleLocalNotification(site: Site) {
        // println(">>> Entering \(__FUNCTION__) <<<")
        
        if (site.allowNotifications == false) { return }
        
        // println("Scheduling a notification for site: \(site.url)")
        
        // remove old notifications before posting new one.
        for notification in site.notifications {
            UIApplication.sharedApplication().cancelLocalNotification(notification)
        }
        
        let dateFor = NSDateFormatter()
        dateFor.timeStyle = .ShortStyle
        dateFor.dateStyle = .ShortStyle
        dateFor.doesRelativeDateFormatting = true
        
        var localNotification = UILocalNotification()
        localNotification.fireDate = NSDate().dateByAddingTimeInterval(NSTimeInterval(arc4random_uniform(UInt32(sites.count))))
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.category = "Nightscout_Category"
        localNotification.userInfo = NSDictionary(object: site.uuid.UUIDString, forKey: Site.PropertyKey.uuidKey) as [NSObject : AnyObject]
        localNotification.alertAction = "View Site"
        
        if let config = site.configuration {
            if let defaults = config.defaults {
                localNotification.alertTitle = "Update for \(defaults.customTitle)"
                if let watch: WatchEntry = site.watchEntry {
                    localNotification.alertBody = "As of \(dateFor.stringFromDate(watch.date)), \(defaults.customTitle) saw a BG of \(watch.sgv!.sgvString) with a delta of \(watch.bgdelta.formattedForBGDelta) \(watch.sgv!.direction.description). Uploader battery: \(watch.batteryString)"
                }
            }
        }
        site.notifications.append(localNotification)
        AppDataManager.sharedInstance.updateSite(site)
        
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    func setupNotificationSettings() {
        println(">>> Entering \(__FUNCTION__) <<<")
        // Specify the notification types.
        var notificationTypes: UIUserNotificationType = UIUserNotificationType.Alert | UIUserNotificationType.Sound | UIUserNotificationType.Badge
        
        // Register the notification settings.
        let newNotificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(newNotificationSettings)
        // TODO: Enabled remote notifications... need to get a server running.
        // UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    // MARK: NSCoding
    
    func saveSites() -> Void {
        AppDataManager.sharedInstance.saveAppData()
    }
}