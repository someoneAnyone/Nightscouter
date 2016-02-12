//
//  AppDelegate.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit
import NightscouterKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, BundleRepresentable {
    
    var window: UIWindow?
    
    var sites: [Site] {
        return AppDataManageriOS.sharedInstance.sites
    }
    
    var timer: NSTimer?
    
    // MARK: AppDelegate Lifecycle
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        // Override point for customization after application launch.
        WatchSessionManager.sharedManager.startSession()
        
        setupNotificationSettings() // Need to move this to when the user adds a server valid to the array.
        
        AppThemeManager.themeApp
        
        window?.tintColor = Theme.Color.windowTintColor
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        self.timer?.invalidate()
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //WatchSessionManager.sharedManager.startSession()
        
        updateDataNotification(nil)
    }
    
    
    // MARK: Background Fetch
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        for site in sites {
            // Get settings for a given site.
            if site.uuid == AppDataManageriOS.sharedInstance.defaultSite {
                fetchSiteData(forSite: site, handler: { (reloaded, returnedSite, returnedIndex, returnedError) -> Void in
                    AppDataManageriOS.sharedInstance.updateSite(returnedSite)
                    // self.scheduleLocalNotification(returnedSite)
                })
            }
        }
        
        // Always return NewData.
        // TODO: Refactor this so we can actually say with some accuracy that we did infact update with NewData or failed. It needs to take into account all the sites... one might fail but other might get new data... should return newdata at that point. If all fail (bad connection) then it should report .Fiailed.
        
        completionHandler(.NewData)
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
            print("Recieved URL: \(url) with options: \(options)")
        #endif
        let schemes = supportedSchemes!
        if (!schemes.contains((url.scheme))) { // If the incoming scheme is not contained within the array of supported schemes return false.
            return false
        }
        
        // We now have an acceptable scheme. Pass the URL to the deep linking handler.
        deepLinkToURL(url)
        
        return true
    }
    
    // MARK: Local Notifications
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        print(">>> Entering \(__FUNCTION__) <<<")
        print("Received a local notification payload: \(notification) with application: \(application)")
        
        processLocalNotification(notification)
    }
    
    
    // MARK: Custom Methods
    func processLocalNotification(notification: UILocalNotification) {
        if let userInfoDict : [NSObject : AnyObject] = notification.userInfo {
            if let uuidString = userInfoDict[Site.PropertyKey.uuidKey] as? String {
                let uuid = NSUUID(UUIDString: uuidString) // Get the uuid from the notification.
                
                _ = NSURL(string: "nightscouter://link/\(Constants.StoryboardViewControllerIdentifier.SiteListPageViewController.rawValue)/\(uuidString)")
                if let site = (sites.filter{ $0.uuid == uuid }.first) { // Use the uuid value to get the site object from the array.
                    if let siteIndex = sites.indexOf(site) { // Use the site object to get its index position in the array.
                        
                        AppDataManageriOS.sharedInstance.currentSiteIndex = siteIndex
                        
                        #if DEDBUG
                            println("User tapped on notification for site: \(site) at index \(siteIndex) with UUID: \(uuid)")
                        #endif
                        
                        let url = NSURL(string: "nightscouter://link/\(Constants.StoryboardViewControllerIdentifier.SiteListPageViewController.rawValue)")
                        deepLinkToURL(url!)
                    }
                }
                //                }
            } else {
                let url = NSURL(string: "nightscouter://link/\(Constants.StoryboardViewControllerIdentifier.SiteFormViewController.rawValue)")
                deepLinkToURL(url!)
            }
        }
    }
    
    func deepLinkToURL(url: NSURL) {
        // Maybe this can be expanded to handle icomming messages from remote or local notifications.
        if let pathComponents = url.pathComponents {
            
            if let queryItems = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)?.queryItems {
                #if DEBUG
                    print("queryItems: \(queryItems)") // Not handling queries at that moment, but might want to.
                #endif
            }
            
            if let navController = self.window?.rootViewController as? UINavigationController { // Get the root view controller's navigation controller.
                navController.popToRootViewControllerAnimated(false) // Return to root viewcontroller without animation.
                let storyboard = self.window?.rootViewController?.storyboard // Grab the storyboard from the rootview.
                var viewControllers = navController.viewControllers // Grab all the current view controllers in the stack.
                for stringID in pathComponents { // iterate through all the path components. Currently the app only has one level of deep linking.
                    if let stor = Constants.StoryboardViewControllerIdentifier(rawValue: stringID) { // Attempt to create a storyboard identifier out of the string.
                        let linkIsAllowed = Constants.StoryboardViewControllerIdentifier.deepLinkableStoryboards.contains(stor) // Check to see if this is an allowed viewcontroller.
                        if linkIsAllowed {
                            let newViewController = storyboard!.instantiateViewControllerWithIdentifier(stringID)
                            
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
                navController.viewControllers = viewControllers // Apply the updated list of view controller to the current navigation controller.
            }
        }
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
        
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: NightscoutAPIClientNotification.DataIsStaleUpdateNow, object: self))
        
        if (self.timer == nil) {
            self.timer = createUpdateTimer()
        }
    }
    
    func scheduleLocalNotification(site: Site) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
            print("Scheduling a notification for site: \(site.url) and is allowed: \(site.allowNotifications)")
        #endif
        
        if (site.allowNotifications == false) { return }
        
        let dateFor = NSDateFormatter()
        dateFor.timeStyle = .ShortStyle
        dateFor.dateStyle = .ShortStyle
        dateFor.doesRelativeDateFormatting = true
        
        let localNotification = UILocalNotification()
        localNotification.fireDate = NSDate().dateByAddingTimeInterval(NSTimeInterval(arc4random_uniform(UInt32(sites.count))))
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.category = "Nightscout_Category"
        localNotification.userInfo = NSDictionary(object: site.uuid.UUIDString, forKey: Site.PropertyKey.uuidKey) as [NSObject : AnyObject]
        localNotification.alertAction = "View Site"
        
        if let config = site.configuration {
            localNotification.alertTitle = "Update for \(config.displayName)"
            
            let units = config.displayUnits
            if let watch: WatchEntry = site.watchEntry {
                localNotification.alertBody = "Last reading: \(dateFor.stringFromDate(watch.date)), BG: \(watch.sgv!.sgvString(forUnits: units)) \(watch.sgv!.direction.emojiForDirection) Delta: \(watch.bgdelta.formattedBGDelta(forUnits: units)) Battery: \(watch.batteryString)%"
            }
        }
        
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    func setupNotificationSettings() {
        print(">>> Entering \(__FUNCTION__) <<<")
        // Specify the notification types.
        let notificationTypes: UIUserNotificationType = [.Alert, .Sound, .Badge]
        
        // Register the notification settings.
        let newNotificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(newNotificationSettings)
        
        // TODO: Enabled remote notifications... need to get a server running.
        // UIApplication.sharedApplication().registerForRemoteNotifications()
        
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    var supportedSchemes: [String]? {
        if let info = infoDictionary {
            var schemes = [String]() // Create an empty array we can later set append available schemes.
            if let bundleURLTypes = info["CFBundleURLTypes"] as? [AnyObject] {
                for (index, _) in bundleURLTypes.enumerate() {
                    if let urlTypeDictionary = bundleURLTypes[index] as? [String : AnyObject] {
                        if let urlScheme = urlTypeDictionary["CFBundleURLSchemes"] as? [String] {
                            schemes += urlScheme // We've found the supported schemes appending to the array.
                            return schemes
                        }
                    }
                }
            }
        }
        
        return nil
    }
}